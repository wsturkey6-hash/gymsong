import ActivityKit
import Foundation
import UserNotifications

@MainActor
@Observable
final class RestTimerService {
    static let shared = RestTimerService()

    private(set) var activeEndsAt: Date?
    private(set) var activeExerciseName: String?

    @ObservationIgnored private var currentActivity: Activity<RestTimerActivityAttributes>?
    @ObservationIgnored private let notificationIdentifier = "rest_timer_done"

    private init() {}

    func requestNotificationAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Start a rest countdown. Replaces any current timer.
    func start(duration: TimeInterval, exerciseName: String, nextSetLabel: String, sessionId: String) async {
        await cancel()
        await requestNotificationAuthorizationIfNeeded()

        let endsAt = Date().addingTimeInterval(duration)
        activeEndsAt = endsAt
        activeExerciseName = exerciseName

        // 1) Live Activity
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attrs = RestTimerActivityAttributes(sessionId: sessionId)
            let state = RestTimerActivityAttributes.ContentState(
                endsAt: endsAt,
                exerciseName: exerciseName,
                nextSetLabel: nextSetLabel
            )
            do {
                currentActivity = try Activity<RestTimerActivityAttributes>.request(
                    attributes: attrs,
                    content: ActivityContent(state: state, staleDate: endsAt.addingTimeInterval(30)),
                    pushType: nil
                )
            } catch {
                // Non-fatal: timer + notification still work without Live Activity.
                print("Live Activity request failed: \(error)")
            }
        }

        // 2) Local notification at end
        scheduleNotification(at: endsAt, body: "\(exerciseName) · \(nextSetLabel)")
    }

    /// Cancel current timer (Live Activity + notification).
    func cancel() async {
        if let activity = currentActivity {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        activeEndsAt = nil
        activeExerciseName = nil
    }

    private func scheduleNotification(at date: Date, body: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "休息結束"
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let triggerDate = max(date, Date().addingTimeInterval(1))
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
