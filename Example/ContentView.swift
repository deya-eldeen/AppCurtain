import SwiftUI
import UIKit
import AppCurtain

struct ContentView: View {
    @State private var lockStyle: CurtainStyle = .blur
    @State private var minimizeStyle: CurtainStyle = .blur
    @State private var curtainTitle = "Payment Screen\n3 fields to completion!"

    private enum CurtainStyle: String, CaseIterable, Identifiable {
        case blur = "Blur"
        case solidColor = "Solid Color"
        case stageCurtain = "Stage Curtains"

        var id: String { rawValue }
    }

    private var lockStyles: [CurtainStyle] {
        CurtainStyle.allCases.filter { $0 != .stageCurtain }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {

                Text("AppCurtain")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Text("Background the app to see the privacy curtain.")
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Lock effect")
                        .font(.headline)

                    Picker("Lock effect", selection: $lockStyle) {
                        ForEach(lockStyles) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Minimize effect")
                        .font(.headline)

                    Picker("Minimize effect", selection: $minimizeStyle) {
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
                    Text("• Lock the simulator to trigger the lock effect.")
                    Text("• Switch apps to see the privacy curtain.")
                    Text("• Change the style with the picker above.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .padding()
        }
        .onAppear {
            applyStyles()
        }
        .onChange(of: lockStyle) { _ in
            applyStyles()
        }
        .onChange(of: minimizeStyle) { _ in
            applyStyles()
        }
        .onChange(of: curtainTitle) { _ in
            applyStyles()
        }
    }

    private func applyStyles() {
        let title = curtainTitle
        Task { @MainActor in
            let lock = curtainStyle(for: lockStyle, title: title)
            let minimize = curtainStyle(for: minimizeStyle, title: title)
            AppCurtain.shared.updateStyles(lockStyle: lock, minimizeStyle: minimize)
        }
    }

    private func curtainStyle(for style: CurtainStyle, title: String) -> AppCurtainStyle {
        switch style {
        case .blur:
            return .blur(.systemChromeMaterial)
        case .solidColor:
            return .custom {
                SolidColorCurtainView(color: .darkGray, title: title)
            }
        case .stageCurtain:
            return .custom {
                StageCurtainView(title: title)
            }
        }
    }
}
