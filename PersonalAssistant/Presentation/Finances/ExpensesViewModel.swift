import Foundation
import Observation

@MainActor
@Observable
final class ExpensesViewModel {
    private let repository: ExpenseRepository

    var expenses: [Expense] = []
    var errorMessage: String?

    init(repository: ExpenseRepository) {
        self.repository = repository
    }

    func load() {
        do {
            expenses = try repository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar as despesas."
        }
    }

    func addExpense(
        title: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory,
        paymentMethod: PaymentMethod,
        notes: String?
    ) {
        let expense = Expense(
            title: title,
            amount: amount,
            date: date,
            category: category,
            paymentMethod: paymentMethod,
            notes: notes
        )
        do {
            try repository.insert(expense)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível salvar a despesa."
        }
    }

    func delete(_ expense: Expense) {
        do {
            try repository.delete(expense)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível excluir a despesa."
        }
    }
}
