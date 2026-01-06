import SwiftUI
import UIKit
import AppCurtain

struct ContentView: View {
    @State private var isRotating = false
    @State private var selectedStyle: CurtainStyle = .blur

    private enum CurtainStyle: String, CaseIterable, Identifiable {
        case blur = "Blur"
        case darkGray = "Dark Gray"
        case rectBottom = "Rect Bottom"
        case rectTop = "Rect Top"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("AppCurtain")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Text("Background the app to see the privacy curtain.")
                    .multilineTextAlignment(.center)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isRotating)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Curtain style")
                        .font(.headline)

                    Picker("Curtain style", selection: $selectedStyle) {
                        ForEach(CurtainStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What you can try:")
                        .font(.headline)
                    Text("• Lock the simulator to trigger the blur.")
                    Text("• Switch apps to confirm the privacy curtain.")
                    Text("• Change the style with the picker above.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    Label("Secure", systemImage: "lock.shield")
                    Label("Private", systemImage: "eye.slash")
                    Label("Fast", systemImage: "bolt.fill")
                }
                .font(.subheadline)
            }
            .padding()
        }
        .onAppear {
            isRotating = true
            applyStyle()
        }
        .onChange(of: selectedStyle) { _ in
            applyStyle()
        }
    }

    private func applyStyle() {
        Task { @MainActor in
            switch selectedStyle {
            case .blur:
                AppCurtain.shared.updateStyle(.blur(.systemChromeMaterial))
            case .darkGray:
                AppCurtain.shared.updateStyle(.color(.darkGray))
            case .rectBottom:
                AppCurtain.shared.updateStyle(.custom {
                    RectCurtainView(direction: .fromBottom, color: .black)
                })
            case .rectTop:
                AppCurtain.shared.updateStyle(.custom {
                    RectCurtainView(direction: .fromTop, color: .black)
                })
            }
        }
    }
}

@MainActor
final class RectCurtainView: UIView, AppCurtainOverlayAnimating {
    enum Direction {
        case fromTop
        case fromBottom
    }

    private let direction: Direction

    init(direction: Direction, color: UIColor) {
        self.direction = direction
        super.init(frame: .zero)
        backgroundColor = color
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func appCurtainWillShow() {
        let offset = bounds.height
        let translation = direction == .fromBottom ? offset : -offset
        transform = CGAffineTransform(translationX: 0, y: translation)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.transform = .identity
        }
    }

    func appCurtainWillHide(completion: @escaping () -> Void) {
        let offset = bounds.height
        let translation = direction == .fromBottom ? offset : -offset
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            self.transform = CGAffineTransform(translationX: 0, y: translation)
        } completion: { _ in
            completion()
        }
    }
}
