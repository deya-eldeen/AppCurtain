import UIKit

/// Visual style for the privacy curtain.
public enum AppCurtainStyle {
    case blur(UIBlurEffect.Style)
    case color(UIColor)
    case custom(@MainActor () -> UIView)

    @MainActor
    fileprivate func makeView() -> UIView {
        switch self {
        case .blur(let style):
            return UIVisualEffectView(effect: UIBlurEffect(style: style))
        case .color(let color):
            let view = UIView()
            view.backgroundColor = color
            return view
        case .custom(let builder):
            return builder()
        }
    }
}

/// Optional hooks for animating a custom curtain overlay.
@MainActor
public protocol AppCurtainOverlayAnimating: AnyObject {
    func appCurtainWillShow()
    func appCurtainWillHide(completion: @escaping () -> Void)
}

/// Manages a privacy curtain that appears when the app backgrounds.
@MainActor
public final class AppCurtain {
    public static let shared = AppCurtain()

    private enum AppCurtainTrigger {
        case lock
        case minimize
    }

    private var lockStyle: AppCurtainStyle = .blur(.systemChromeMaterial)
    private var minimizeStyle: AppCurtainStyle = .blur(.systemChromeMaterial)
    private var windowProvider: @MainActor () -> UIWindow? = AppCurtain.defaultWindowProvider
    private var observerTokens: [NSObjectProtocol] = []
    private weak var overlayView: UIView?
    private var lastTrigger: AppCurtainTrigger?

    public init() {}

    /// Begins observing app state changes and showing the curtain as needed.
    public func start(
        style: AppCurtainStyle = .blur(.systemChromeMaterial),
        windowProvider: @escaping @MainActor () -> UIWindow? = AppCurtain.defaultWindowProvider
    ) {
        start(lockStyle: style, minimizeStyle: style, windowProvider: windowProvider)
    }

    /// Begins observing app state changes with separate styles for lock and minimize.
    public func start(
        lockStyle: AppCurtainStyle = .blur(.systemChromeMaterial),
        minimizeStyle: AppCurtainStyle = .blur(.systemChromeMaterial),
        windowProvider: @escaping @MainActor () -> UIWindow? = AppCurtain.defaultWindowProvider
    ) {
        stop()
        self.lockStyle = lockStyle
        self.minimizeStyle = minimizeStyle
        self.windowProvider = windowProvider

        let center = NotificationCenter.default
        observerTokens = [
            center.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.showCurtain(for: .minimize)
                }
            },
            center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.showCurtainIfAllowed(for: .minimize)
                }
            },
            center.addObserver(
                forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.showCurtain(for: .lock)
                }
            },
            center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hideCurtain()
                }
            },
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hideCurtain()
                }
            },
        ]
    }

    /// Stops observing and removes any visible curtain.
    public func stop() {
        for token in observerTokens {
            NotificationCenter.default.removeObserver(token)
        }
        observerTokens.removeAll()
        hideCurtain()
    }

    /// Updates the curtain style and refreshes it if currently visible.
    public func updateStyle(_ style: AppCurtainStyle) {
        self.lockStyle = style
        self.minimizeStyle = style
        refreshVisibleCurtain()
    }

    /// Updates the styles for lock and minimize events.
    public func updateStyles(lockStyle: AppCurtainStyle, minimizeStyle: AppCurtainStyle) {
        self.lockStyle = lockStyle
        self.minimizeStyle = minimizeStyle
        refreshVisibleCurtain()
    }

    /// Resolves a suitable window from connected scenes.
    public static func defaultWindowProvider() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return activeScene.windows.first(where: { $0.isKeyWindow }) ?? activeScene.windows.first
        }

        if let inactiveScene = scenes.first(where: { $0.activationState == .foregroundInactive }) {
            return inactiveScene.windows.first(where: { $0.isKeyWindow }) ?? inactiveScene.windows.first
        }

        return scenes.first?.windows.first
    }

    private func showCurtain(for trigger: AppCurtainTrigger) {
        guard let window = windowProvider() else { return }

        let previousTrigger = lastTrigger
        lastTrigger = trigger

        if let overlay = overlayView {
            if overlay.superview !== window {
                overlay.removeFromSuperview()
                overlayView = nil
            } else if previousTrigger == trigger {
                overlay.frame = window.bounds
                return
            } else {
                overlay.removeFromSuperview()
                overlayView = nil
            }
        }

        let style = trigger == .lock ? lockStyle : minimizeStyle
        let overlay = style.makeView()
        overlay.frame = window.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = false
        window.addSubview(overlay)
        overlayView = overlay
        overlay.setNeedsLayout()
        overlay.layoutIfNeeded()

        if let animatingOverlay = overlay as? AppCurtainOverlayAnimating {
            animatingOverlay.appCurtainWillShow()
        }
    }

    private func showCurtainIfAllowed(for trigger: AppCurtainTrigger) {
        if trigger == .minimize, lastTrigger == .lock {
            return
        }
        showCurtain(for: trigger)
    }

    private func hideCurtain() {
        guard let overlay = overlayView else { return }

        if let animatingOverlay = overlay as? AppCurtainOverlayAnimating {
            animatingOverlay.appCurtainWillHide { [weak self] in
                overlay.removeFromSuperview()
                self?.overlayView = nil
            }
        } else {
            overlay.removeFromSuperview()
            overlayView = nil
        }
    }

    private func refreshVisibleCurtain() {
        guard overlayView != nil else { return }
        removeCurtainImmediately()
        if let trigger = lastTrigger {
            showCurtain(for: trigger)
        }
    }

    private func removeCurtainImmediately() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
}
