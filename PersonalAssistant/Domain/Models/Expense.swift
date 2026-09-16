import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var paymentMethod: PaymentMethod
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory,
        paymentMethod: PaymentMethod,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.createdAt = createdAt
    }
}
