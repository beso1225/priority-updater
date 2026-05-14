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
}

semaphore.wait()
