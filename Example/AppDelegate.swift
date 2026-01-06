import UIKit
import AppCurtain

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      AppCurtain.shared.start(style: .blur(.regular))
        return true
    }
}
