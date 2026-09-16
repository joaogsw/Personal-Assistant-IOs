import SwiftUI

struct RecurringBillsView: View {
    @State var viewModel: RecurringBillsViewModel
    @State private var isPresentingAddBill = false

    var body: some View {
        List {
            if viewModel.bills.isEmpty {
                EmptyStateView(systemImage: "repeat.circle", title: "Nenhuma conta recorrente", message: "Cadastre uma conta recorrente.")
            } else {
                ForEach(viewModel.bills) { bill in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bill.title)
                            Text("Próximo vencimento: \(bill.nextDueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(bill.amount.currencyFormatted)
                    }
                    .swipeActions {
                        Button("Marcar como paga") {
                            viewModel.markAsPaid(bill)
                        }
                        .tint(.green)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.delete(viewModel.bills[index])
                    }
                }
            }
        }
        .navigationTitle("Contas Recorrentes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddBill = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddBill) {
            AddRecurringBillView { title, amount, recurrence, nextDueDate, reminderDaysBefore, category in
                viewModel.addRecurringBill(
                    title: title,
                    amount: amount,
                    recurrence: recurrence,
                    nextDueDate: nextDueDate,
                    reminderDaysBefore: reminderDaysBefore,
                    category: category
                )
            }
        }
        .task { viewModel.load() }
    }
}
