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
        let calender = Calendar.current

        for reminder in reminders {
            if reminder.calendar.title != "課題" {
                continue
            }
            guard let title = reminder.title else {
                continue
            }
            print("There is a reminder with title: \(title)")
            let priority = reminder.priority
            print("Priority: \(priority)")
            reminder.priority = 1
            do {
                try store.save(reminder, commit: true)
                print("Updated priority to 1")
            } catch {
                print("Failed to update reminder: \(error)")
            }
        }
        semaphore.signal()
    }
}

semaphore.wait()
