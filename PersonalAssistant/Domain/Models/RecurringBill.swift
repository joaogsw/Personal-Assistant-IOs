import Foundation
import SwiftData

@Model
final class RecurringBill {
    var id: UUID
    var title: String
    var amount: Decimal
    var recurrence: RecurrenceFrequency
    var nextDueDate: Date
    var reminderDaysBefore: Int
    var isActive: Bool
    var category: ExpenseCategory
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        recurrence: RecurrenceFrequency,
        nextDueDate: Date,
        reminderDaysBefore: Int = 0,
        isActive: Bool = true,
        category: ExpenseCategory,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.recurrence = recurrence
        self.nextDueDate = nextDueDate
        self.reminderDaysBefore = reminderDaysBefore
        self.isActive = isActive
        self.category = category
        self.createdAt = createdAt
    }
}
