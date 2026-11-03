import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAuth

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Initialize Firebase
        FirebaseApp.configure()
        // Sign in to Firebase anonymously
        if Auth.auth().currentUser == nil {

            Auth.auth().signInAnonymously { result, error in

                if let error = error {
                    print("Firebase Auth error:", error.localizedDescription)
                    return
                }

                print(
                    "Firebase anonymous sign-in successful:",
                    result?.user.isAnonymous == true
                )
            }

        } else {
            print("Firebase user session restored")
        }

        print("Firebase initialized:",
              FirebaseApp.app() != nil)

        // Existing notification setup
        UNUserNotificationCenter.current().delegate = self
        BPMMonitor.shared.requestNotificationPermission()

        return true
    }
    
    // This method is called when a notification is delivered while the app is in foreground
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions) -> Void) {
            // Show banner and play sound even if app is in foreground
            completionHandler([.banner, .sound])
        }

    // Optional: handle when a user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification tapped: \(response.notification.request.content.title)")
        completionHandler()
    }

    // Push registration success
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device token: \(token)")
    }

    // Push registration failure
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Scene support
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    
}
