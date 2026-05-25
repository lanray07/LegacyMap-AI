import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published var authorizationGranted = false
    @Published var errorMessage: String?

    func requestAuthorization() async {
        do {
            authorizationGranted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleRestorationReminder(title: String, notes: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = notes
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 24, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
