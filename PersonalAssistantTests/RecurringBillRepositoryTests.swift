import Foundation
import Testing
@testable import PersonalAssistant

struct RecurringBillRepositoryTests {
    @Test func markingBillAsPaidAdvancesNextDueDate() throws {
        let context = TestModelContainerFactory.makeContext()
        let calendar = Calendar(identifier: .gregorian)
        let repository = SwiftDataRecurringBillRepository(context: context, calendar: calendar)
        let firstDueDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!

        let bill = RecurringBill(
            title: "Aluguel",
            amount: 2000,
            recurrence: .monthly,
            nextDueDate: firstDueDate,
            category: .housing
        )
        try repository.insert(bill)
        try repository.save()

        try repository.markAsPaid(bill)
        try repository.save()

        let components = calendar.dateComponents([.year, .month, .day], from: bill.nextDueDate)
        #expect(components.month == 4)
        #expect(components.day == 10)
    }
}
