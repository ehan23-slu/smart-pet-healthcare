// this page makes Alert

import Foundation
import UserNotifications
import UIKit

class BPMMonitor {
    
    static let shared = BPMMonitor()
    
    private init() {}
    
    // Main logic to check if BPM is normal and respond accordingly
    func checkBPM(for pet: Pet, bpm: Int) {
        if isBPMNormal(for: pet, bpm: bpm) {
            return
        }
        
        let title = "⚠️ Abnormal Heart Rate"
        let message = "\(pet.name)’s heart rate is \(bpm) BPM, which is outside the normal range."
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.showInAppAlert(title: title, message: message)
            } else {
                self.sendNotification(title: title, message: message)
            }

        }

    }
    
    // BPM thresholds based on pet species and age
    func isBPMNormal(for pet: Pet, bpm: Int) -> Bool {
        switch pet.species {
            
        case .cat:
            return bpm >= 140 && bpm <= 220
            
        case .dog:
            let isPuppy = self.isPuppy(birthDate: pet.birthDate)
            if isPuppy {
                return bpm >= 60 && bpm <= 180
            } else {
                return bpm >= 60 && bpm <= 160
            }
        }
    }
    
    
    private func isPuppy(birthDate: Date) -> Bool {
        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        return ageInMonths < 12
    }
    
    
    // Local notification setup
    private func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        // Optional: delay by 1 second to ensure delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Ask the user for permission (call once at app startup)
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
            print("🔔 Notification permission granted: \(granted)")
        }
    }
    
    // Fallback alert when app is active (modern window API)
    private func showInAppAlert(title: String, message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("⚠️ Unable to find key window to show alert.")
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootVC.present(alert, animated: true)
    }
}
