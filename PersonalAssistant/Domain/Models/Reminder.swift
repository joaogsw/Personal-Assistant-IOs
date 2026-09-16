import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var reminderDate: Date
    var isCompleted: Bool
    /// Optional link to another entity (e.g. a RecurringBill or Installment) this reminder relates to.
    var relatedEntityID: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        reminderDate: Date,
        isCompleted: Bool = false,
        relatedEntityID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.relatedEntityID = relatedEntityID
        self.createdAt = createdAt
    }
}
