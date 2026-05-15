import Foundation

#if canImport(EventKit)
import EventKit
#endif

public struct ReminderUpdateSummary: Sendable {
    public let totalReminders: Int
    public let updatedReminders: Int

    public init(totalReminders: Int, updatedReminders: Int) {
        self.totalReminders = totalReminders
        self.updatedReminders = updatedReminders
    }
}

public enum ReminderPriorityUpdaterError: Error {
    case eventKitUnavailable
    case permissionDenied
}

public final class ReminderPriorityUpdater {
    public init() {}

    public static func priority(daysUntilDue: Int) -> Int {
        switch daysUntilDue {
        case 0...3:
            return 1
        case 4...7:
            return 5
        case 8...14:
            return 9
        default:
            return 0
        }
    }

    #if canImport(EventKit)
    @available(iOS 17.0, macOS 14.0, *)
    public func updateReminderPriorities(
        store: EKEventStore = EKEventStore(),
        completion: @escaping @Sendable (Result<ReminderUpdateSummary, Error>) -> Void
    ) {
        store.requestFullAccessToReminders { granted, _ in
            guard granted else {
                completion(.failure(ReminderPriorityUpdaterError.permissionDenied))
                return
            }

            let calendars = store.calendars(for: .reminder)
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: nil,
                ending: nil,
                calendars: calendars
            )

            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders else {
                    completion(.success(ReminderUpdateSummary(totalReminders: 0, updatedReminders: 0)))
                    return
                }

                let now = Date()
                let calendar = Calendar.current
                var updatedCount = 0

                for reminder in reminders {
                    guard
                        let dueComponents = reminder.dueDateComponents,
                        let dueDate = calendar.date(from: dueComponents)
                    else {
                        continue
                    }

                    let daysUntilDue = calendar.dateComponents([.day], from: now, to: dueDate).day ?? Int.max
                    let newPriority = Self.priority(daysUntilDue: daysUntilDue)

                    if reminder.priority != newPriority {
                        reminder.priority = newPriority
                        do {
                            try store.save(reminder, commit: false)
                            updatedCount += 1
                        } catch {
                            completion(.failure(error))
                            return
                        }
                    }
                }

                do {
                    try store.commit()
                    completion(.success(ReminderUpdateSummary(totalReminders: reminders.count, updatedReminders: updatedCount)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    #else
    public func updateReminderPriorities(
        completion: @escaping @Sendable (Result<ReminderUpdateSummary, Error>) -> Void
    ) {
        completion(.failure(ReminderPriorityUpdaterError.eventKitUnavailable))
    }
    #endif
}
