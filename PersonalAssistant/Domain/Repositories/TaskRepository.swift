import Foundation

/// Abstracts persistence for `TaskItem`.
protocol TaskRepository {
    func fetchAll() throws -> [TaskItem]
    func insert(_ task: TaskItem) throws
    func delete(_ task: TaskItem) throws
    func complete(_ task: TaskItem) throws
    func save() throws
}
