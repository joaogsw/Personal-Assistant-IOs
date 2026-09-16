import Foundation
import Testing
@testable import PersonalAssistant

struct ExpenseRepositoryTests {
    @Test func insertingAndFetchingExpensePersistsIt() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataExpenseRepository(context: context)

        let expense = Expense(
            title: "Camisa",
            amount: 400,
            date: .now,
            category: .shopping,
            paymentMethod: .creditCard
        )
        try repository.insert(expense)
        try repository.save()

        let fetched = try repository.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Camisa")
        #expect(fetched.first?.amount == 400)
    }

    @Test func deletingExpenseRemovesIt() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataExpenseRepository(context: context)

        let expense = Expense(title: "Café", amount: 20, date: .now, category: .food, paymentMethod: .pix)
        try repository.insert(expense)
        try repository.save()

        try repository.delete(expense)
        try repository.save()

        #expect(try repository.fetchAll().isEmpty)
    }
}
