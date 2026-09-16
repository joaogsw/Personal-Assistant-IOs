import Foundation

/// Splits a purchase into an `InstallmentPlan` with its `Installment` children.
/// Pure logic, no persistence — safe to unit test without SwiftData.
enum InstallmentPlanGenerator {
    static func generate(
        title: String,
        totalAmount: Decimal,
        installmentCount: Int,
        firstInstallmentDate: Date,
        paymentMethod: PaymentMethod,
        calendar: Calendar = .current
    ) -> InstallmentPlan {
        precondition(installmentCount > 0, "installmentCount must be greater than zero")
        precondition(totalAmount > 0, "totalAmount must be greater than zero")

        let plan = InstallmentPlan(
            title: title,
            totalAmount: totalAmount,
            installmentCount: installmentCount,
            firstInstallmentDate: firstInstallmentDate,
            paymentMethod: paymentMethod
        )

        let baseAmount = roundedCurrency(totalAmount / Decimal(installmentCount))
        let amountAllocatedBeforeLast = baseAmount * Decimal(installmentCount - 1)
        let lastAmount = roundedCurrency(totalAmount - amountAllocatedBeforeLast)

        var installments: [Installment] = []
        installments.reserveCapacity(installmentCount)

        for index in 0..<installmentCount {
            let dueDate = CalendarDateMath.addingMonthsClamped(index, to: firstInstallmentDate, calendar: calendar)
            let amount = (index == installmentCount - 1) ? lastAmount : baseAmount
            installments.append(
                Installment(
                    installmentNumber: index + 1,
                    amount: amount,
                    dueDate: dueDate,
                    plan: plan
                )
            )
        }

        plan.installments = installments
        return plan
    }

    private static func roundedCurrency(_ value: Decimal) -> Decimal {
        var mutableValue = value
        var result = Decimal()
        NSDecimalRound(&result, &mutableValue, 2, .plain)
        return result
    }
}
