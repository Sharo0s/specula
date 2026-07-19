import Foundation
import UserNotifications

// MARK: - Notifications système (panne / rétablissement)
// L'app affiche déjà ses notifications en interne ; ici on les délivre aussi
// au système (bannière + son), y compris quand l'app est au premier plan.

final class SystemNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = SystemNotifier()

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func post(title: String, body: String, critical: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = critical ? .default : nil
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // Bannière même au premier plan
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
