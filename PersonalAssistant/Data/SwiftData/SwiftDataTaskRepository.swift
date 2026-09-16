import Foundation
import SwiftData

final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext
    private let dateProvider: DateProviding

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider()) {
        self.context = context
        self.dateProvider = dateProvider
    }

    func fetchAll() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ task: TaskItem) throws {
        context.insert(task)
    }

    func delete(_ task: TaskItem) throws {
        context.delete(task)
    }

    func complete(_ task: TaskItem) throws {
        task.isCompleted = true
        task.completedAt = dateProvider.now()
    }

    func save() throws {
        try context.save()
    }
}
