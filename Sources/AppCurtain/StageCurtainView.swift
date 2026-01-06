import UIKit

/// Two-panel stage curtain that slides in from left/right with gradient fabric tones.
@MainActor
public final class StageCurtainView: UIView, AppCurtainOverlayAnimating {
    private let leftCurtain = UIView()
    private let rightCurtain = UIView()
    private let leftGradient = CAGradientLayer()
    private let rightGradient = CAGradientLayer()
    private let titleLabel = UILabel()
    private var lastSize: CGSize = .zero

    public convenience init(title: String) {
        self.init(frame: .zero)
        self.title = title
    }

    public var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        configureTitleLabel()
        setupCurtain(leftCurtain, gradient: leftGradient, flip: false)
        setupCurtain(rightCurtain, gradient: rightGradient, flip: true)
        addSubview(leftCurtain)
        addSubview(rightCurtain)
        addSubview(titleLabel)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func appCurtainWillShow() {
        let offset = bounds.width / 2
        leftCurtain.transform = CGAffineTransform(translationX: -offset, y: 0)
        rightCurtain.transform = CGAffineTransform(translationX: offset, y: 0)
        titleLabel.alpha = 0
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.leftCurtain.transform = .identity
            self.rightCurtain.transform = .identity
        } completion: { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: 0.05,
                options: [.curveEaseOut]
            ) {
                self.titleLabel.alpha = 1
            }
        }
    }

    public func appCurtainWillHide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseIn]) {
            self.titleLabel.alpha = 0
        }
        let offset = bounds.width / 2
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            self.leftCurtain.transform = CGAffineTransform(translationX: -offset, y: 0)
            self.rightCurtain.transform = CGAffineTransform(translationX: offset, y: 0)
        } completion: { _ in
            completion()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutCurtains()
        layoutTitleLabel()
    }

    private func setupCurtain(_ view: UIView, gradient: CAGradientLayer, flip: Bool) {
        view.layer.addSublayer(gradient)
        let brightRed = UIColor(red: 0.82, green: 0.02, blue: 0.05, alpha: 1)
        let deepRed = UIColor(red: 0.45, green: 0.0, blue: 0.02, alpha: 1)
        let nearBlack = UIColor(red: 0.06, green: 0.01, blue: 0.01, alpha: 1)
        gradient.colors = [brightRed.cgColor, deepRed.cgColor, nearBlack.cgColor]
        gradient.startPoint = CGPoint(x: flip ? 1.0 : 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: flip ? 0.0 : 1.0, y: 1.0)
    }

    private func layoutCurtains() {
        guard bounds.size != lastSize else { return }
        lastSize = bounds.size
        let halfWidth = bounds.width / 2
        leftCurtain.frame = CGRect(x: 0, y: 0, width: halfWidth, height: bounds.height)
        rightCurtain.frame = CGRect(x: halfWidth, y: 0, width: halfWidth, height: bounds.height)
        leftGradient.frame = leftCurtain.bounds
        rightGradient.frame = rightCurtain.bounds
    }

    private func configureTitleLabel() {
        titleLabel.textColor = .white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
    }

    private func layoutTitleLabel() {
        guard bounds.width > 0 else { return }
        let inset: CGFloat = 24
        let maxWidth = bounds.width - (inset * 2)
        let size = titleLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        titleLabel.frame = CGRect(
            x: (bounds.width - min(size.width, maxWidth)) / 2,
            y: (bounds.height - size.height) / 2,
            width: min(size.width, maxWidth),
            height: size.height
        )
    }
}
