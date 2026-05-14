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

        for reminder in reminders {
            if reminder.calendar.title != "課題" {
                continue
            }
            print("There is a reminder with title: \(reminder.title)")
        }
        semaphore.signal()
    }
}

semaphore.wait()
