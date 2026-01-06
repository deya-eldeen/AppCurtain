import SwiftUI
import UIKit
import AppCurtain

struct ContentView: View {
    @State private var isRotating = false
    @State private var selectedStyle: CurtainStyle = .blur
    @State private var curtainTitle = "Payment Screen\n3 fields to completion!"

    private enum CurtainStyle: String, CaseIterable, Identifiable {
        case blur = "Blur"
        case solidColor = "Solid Color"
        case stageCurtain = "Stage Curtains"

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
                    Text("Curtain title")
                        .font(.headline)
                    TextField("Enter title", text: $curtainTitle)
                        .textFieldStyle(.roundedBorder)
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
            case .solidColor:
                AppCurtain.shared.updateStyle(.custom {
                    SolidColorCurtainView(color: .darkGray, title: curtainTitle)
                })
            case .stageCurtain:
                AppCurtain.shared.updateStyle(.custom {
                    StageCurtainView(title: curtainTitle)
                })
            }
        }
    }
}
