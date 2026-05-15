import Foundation
import EventKit

let store = EKEventStore()

let semaphore = DispatchSemaphore(value: 0)

store.requestFullAccessToReminders { granted, error in
    guard granted else {
        print("Permission denied")
        semaphore.signal()
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
            semaphore.signal()
            return
        }
        let now = Date()
        let calendar = Calendar.current

        for reminder in reminders {
            guard let dueComponents = reminder.dueDateComponents,
                let dueDate = calendar.date(from: dueComponents) else {
                    continue
            }
            print("Processing reminder: \(reminder.title ?? "No Title") with due date: \(dueDate)")
            let days = calendar.dateComponents([.day], from: now, to: dueDate).day ?? Int.max

            var newPriority: Int?
            if days <= 3 && days >= 0 {
                newPriority = 1
            } else if days <= 7 && days > 3 {
                newPriority = 5
            } else if days <= 14 && days > 7 {
                newPriority = 9 
            } else {
                newPriority = 0
            }

            if let newPriority = newPriority, reminder.priority != newPriority {
                reminder.priority = newPriority
                do {
                    try store.save(reminder, commit: true)
                    print("Updated reminder: \(reminder.title ?? "No Title") with new priority: \(newPriority)")
                } catch {
                    print("Failed to update reminder: \(error)")
                }
            }
        }
        do {
            try store.commit()
        } catch {
            print("Failed to commit changes: \(error)")
        }
        semaphore.signal()
    }
}

semaphore.wait()

