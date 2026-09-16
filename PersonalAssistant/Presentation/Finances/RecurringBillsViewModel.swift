import Foundation
import Observation

@MainActor
@Observable
final class RecurringBillsViewModel {
    private let repository: RecurringBillRepository

    var bills: [RecurringBill] = []
    var errorMessage: String?

    init(repository: RecurringBillRepository) {
        self.repository = repository
    }

    func load() {
        do {
            bills = try repository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar as contas recorrentes."
        }
    }

    func addRecurringBill(
        title: String,
        amount: Decimal,
        recurrence: RecurrenceFrequency,
        nextDueDate: Date,
        reminderDaysBefore: Int,
        category: ExpenseCategory
    ) {
        let bill = RecurringBill(
            title: title,
            amount: amount,
            recurrence: recurrence,
            nextDueDate: nextDueDate,
            reminderDaysBefore: reminderDaysBefore,
            category: category
        )
        do {
            try repository.insert(bill)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível salvar a conta recorrente."
        }
    }

    func markAsPaid(_ bill: RecurringBill) {
        do {
            try repository.markAsPaid(bill)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível atualizar a conta."
        }
    }

    func delete(_ bill: RecurringBill) {
        do {
            try repository.delete(bill)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível excluir a conta."
        }
    }
}
