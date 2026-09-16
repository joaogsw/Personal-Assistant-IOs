import Foundation
import SwiftData

@Model
final class InstallmentPlan {
    var id: UUID
    var title: String
    var totalAmount: Decimal
    var installmentCount: Int
    var firstInstallmentDate: Date
    var paymentMethod: PaymentMethod
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Installment.plan)
    var installments: [Installment] = []

    init(
        id: UUID = UUID(),
        title: String,
        totalAmount: Decimal,
        installmentCount: Int,
        firstInstallmentDate: Date,
        paymentMethod: PaymentMethod,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.totalAmount = totalAmount
        self.installmentCount = installmentCount
        self.firstInstallmentDate = firstInstallmentDate
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
    }
}
