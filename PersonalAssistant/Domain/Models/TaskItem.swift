import Foundation
import SwiftData

/// Named `TaskItem` (not `Task`) to avoid colliding with Swift Concurrency's `Task`.
@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var priority: TaskPriority
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: TaskPriority = .medium,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
        self.createdAt = createdAt
    }
}
