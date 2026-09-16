import Foundation
import SwiftData

final class SwiftDataReminderRepository: ReminderRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Reminder] {
        let descriptor = FetchDescriptor<Reminder>(sortBy: [SortDescriptor(\.reminderDate, order: .forward)])
        return try context.fetch(descriptor)
    }

    func insert(_ reminder: Reminder) throws {
        context.insert(reminder)
    }

    func delete(_ reminder: Reminder) throws {
        context.delete(reminder)
    }

    func complete(_ reminder: Reminder) throws {
        reminder.isCompleted = true
    }

    func save() throws {
        try context.save()
    }
}
