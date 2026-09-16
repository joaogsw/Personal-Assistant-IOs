import SwiftUI

struct FinancesView: View {
    let expenseRepository: ExpenseRepository
    let installmentRepository: InstallmentRepository
    let recurringBillRepository: RecurringBillRepository

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Despesas") {
                    ExpenseListView(viewModel: ExpensesViewModel(repository: expenseRepository))
                }
                NavigationLink("Compras Parceladas") {
                    InstallmentsView(viewModel: InstallmentsViewModel(repository: installmentRepository))
                }
                NavigationLink("Contas Recorrentes") {
                    RecurringBillsView(viewModel: RecurringBillsViewModel(repository: recurringBillRepository))
                }
            }
            .navigationTitle("Finanças")
        }
    }
}
