import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let maxNotifications = 64

    private init() {}

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("[NotificationService] Permission error: \(error.localizedDescription)")
            }
            print("[NotificationService] Permission granted: \(granted)")
        }
    }

    // MARK: - Assignment Notifications

    /// Schedules reminder notifications 24 hours and 2 hours before each assignment due date.
    /// Respects the 64-notification system limit by prioritizing nearest deadlines.
    func scheduleAssignmentNotifications(syllabus: SyllabusSchedule) {
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var requests: [(date: Date, request: UNNotificationRequest)] = []

        for week in syllabus.lectureSchedule {
            guard let assignments = week.assignments else { continue }
            for assignment in assignments {
                guard let dueDate = dateFormatter.date(from: assignment.dueDate) else { continue }

                // 24-hour reminder
                if let reminder24h = Calendar.current.date(byAdding: .hour, value: -24, to: dueDate),
                   reminder24h > now {
                    let request = makeNotificationRequest(
                        identifier: "assign-24h-\(assignment.id)",
                        title: "Assignment Due Tomorrow",
                        body: assignment.name,
                        triggerDate: reminder24h
                    )
                    requests.append((date: reminder24h, request: request))
                }

                // 2-hour reminder
                if let reminder2h = Calendar.current.date(byAdding: .hour, value: -2, to: dueDate),
                   reminder2h > now {
                    let request = makeNotificationRequest(
                        identifier: "assign-2h-\(assignment.id)",
                        title: "Assignment Due Soon",
                        body: "\(assignment.name) is due in 2 hours",
                        triggerDate: reminder2h
                    )
                    requests.append((date: reminder2h, request: request))
                }
            }
        }

        // Sort by date and keep only up to the limit
        let limited = requests
            .sorted { $0.date < $1.date }
            .prefix(maxNotifications)

        for item in limited {
            center.add(item.request) { error in
                if let error {
                    print("[NotificationService] Failed to schedule: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Helpers

    private func makeNotificationRequest(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
