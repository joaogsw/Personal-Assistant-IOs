import SwiftUI

struct ExpenseListView: View {
    @State var viewModel: ExpensesViewModel
    @State private var isPresentingAddExpense = false

    var body: some View {
        List {
            if viewModel.expenses.isEmpty {
                EmptyStateView(systemImage: "cart", title: "Nenhuma despesa", message: "Adicione sua primeira despesa.")
            } else {
                ForEach(viewModel.expenses) { expense in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(expense.title)
                            Spacer()
                            Text(expense.amount.currencyFormatted)
                        }
                        Text(expense.category.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.delete(viewModel.expenses[index])
                    }
                }
            }
        }
        .navigationTitle("Despesas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddExpense) {
            AddExpenseView { title, amount, date, category, paymentMethod, notes in
                viewModel.addExpense(
                    title: title,
                    amount: amount,
                    date: date,
                    category: category,
                    paymentMethod: paymentMethod,
                    notes: notes
                )
            }
        }
        .task { viewModel.load() }
    }
}
