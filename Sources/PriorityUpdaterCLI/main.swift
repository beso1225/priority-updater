import Dispatch
import Foundation
import PriorityUpdaterCore

#if os(macOS) && canImport(EventKit)
let updater = ReminderPriorityUpdater()
let semaphore = DispatchSemaphore(value: 0)

if #available(macOS 14.0, *) {
    updater.updateReminderPriorities { result in
        switch result {
        case .success(let summary):
            print("Scanned \(summary.totalReminders) reminders; updated \(summary.updatedReminders); failed \(summary.failedReminders).")
        case .failure(let error):
            print("Failed to update reminders: \(error)")
        }
        semaphore.signal()
    }
    semaphore.wait()
} else {
    print("PriorityUpdater requires macOS 14 or newer.")
}
#else
print("The CLI target is only supported on macOS with EventKit.")
#endif
