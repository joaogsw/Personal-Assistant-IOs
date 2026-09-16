import Foundation
import Testing
@testable import PersonalAssistant

struct InstallmentPlanGeneratorTests {
    @Test func splitsAmountEvenlyAcrossInstallments() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!

        let plan = InstallmentPlanGenerator.generate(
            title: "Camisa",
            totalAmount: 400,
            installmentCount: 4,
            firstInstallmentDate: firstDate,
            paymentMethod: .creditCard,
            calendar: calendar
        )

        #expect(plan.installments.count == 4)
        #expect(plan.installments.allSatisfy { $0.amount == 100 })
        let total = plan.installments.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(total == 400)
    }

    @Test func distributesRoundingRemainderToLastInstallment() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!

        let plan = InstallmentPlanGenerator.generate(
            title: "Compra",
            totalAmount: 100,
            installmentCount: 3,
            firstInstallmentDate: firstDate,
            paymentMethod: .creditCard,
            calendar: calendar
        )

        let amounts = plan.installments.sorted { $0.installmentNumber < $1.installmentNumber }.map(\.amount)
        #expect(amounts[0] == Decimal(string: "33.33"))
        #expect(amounts[1] == Decimal(string: "33.33"))
        #expect(amounts[2] == Decimal(string: "33.34"))
        let total = amounts.reduce(Decimal(0), +)
        #expect(total == 100)
    }

    @Test func assignsSequentialMonthlyDueDates() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 10))!

        let plan = InstallmentPlanGenerator.generate(
            title: "Compra",
            totalAmount: 1200,
            installmentCount: 6,
            firstInstallmentDate: firstDate,
            paymentMethod: .creditCard,
            calendar: calendar
        )

        let dueDates = plan.installments.sorted { $0.installmentNumber < $1.installmentNumber }.map(\.dueDate)
        let expectedMonths = [10, 11, 12, 1, 2, 3]
        let expectedYears = [2026, 2026, 2026, 2027, 2027, 2027]
        for (index, date) in dueDates.enumerated() {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(components.day == 10)
            #expect(components.month == expectedMonths[index])
            #expect(components.year == expectedYears[index])
        }
    }

    @Test func clampsDayWhenTargetMonthIsShorter() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!

        let plan = InstallmentPlanGenerator.generate(
            title: "Compra",
            totalAmount: 200,
            installmentCount: 2,
            firstInstallmentDate: firstDate,
            paymentMethod: .creditCard,
            calendar: calendar
        )

        let dueDates = plan.installments.sorted { $0.installmentNumber < $1.installmentNumber }.map(\.dueDate)
        let secondComponents = calendar.dateComponents([.year, .month, .day], from: dueDates[1])
        #expect(secondComponents.month == 2)
        #expect(secondComponents.day == 28) // 2026 is not a leap year
    }
}
