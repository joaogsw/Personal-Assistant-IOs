import Foundation
import SwiftData

@Model
final class Installment {
    var id: UUID
    var installmentNumber: Int
    var amount: Decimal
    var dueDate: Date
    var isPaid: Bool
    var paidAt: Date?
    var plan: InstallmentPlan?

    init(
        id: UUID = UUID(),
        installmentNumber: Int,
        amount: Decimal,
        dueDate: Date,
        isPaid: Bool = false,
        paidAt: Date? = nil,
        plan: InstallmentPlan? = nil
    ) {
        self.id = id
        self.installmentNumber = installmentNumber
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paidAt = paidAt
        self.plan = plan
    }
}
