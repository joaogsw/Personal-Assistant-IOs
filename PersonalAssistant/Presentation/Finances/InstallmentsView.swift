import SwiftUI

struct InstallmentsView: View {
    @State var viewModel: InstallmentsViewModel
    @State private var isPresentingAddPurchase = false

    var body: some View {
        List {
            if viewModel.plans.isEmpty {
                EmptyStateView(systemImage: "creditcard", title: "Nenhuma compra parcelada", message: "Adicione uma compra parcelada.")
            } else {
                ForEach(viewModel.plans) { plan in
                    NavigationLink {
                        InstallmentPlanDetailView(plan: plan, viewModel: viewModel)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.title)
                            Text("\(plan.installmentCount)x — Total \(plan.totalAmount.currencyFormatted)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.delete(viewModel.plans[index])
                    }
                }
            }
        }
        .navigationTitle("Compras Parceladas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddPurchase = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddPurchase) {
            AddInstallmentPurchaseView { title, totalAmount, count, firstDate, method in
                viewModel.addInstallmentPurchase(
                    title: title,
                    totalAmount: totalAmount,
                    installmentCount: count,
                    firstInstallmentDate: firstDate,
                    paymentMethod: method
                )
            }
        }
        .task { viewModel.load() }
    }
}

struct InstallmentPlanDetailView: View {
    let plan: InstallmentPlan
    var viewModel: InstallmentsViewModel

    private var sortedInstallments: [Installment] {
        plan.installments.sorted { $0.installmentNumber < $1.installmentNumber }
    }

    var body: some View {
        List(sortedInstallments) { installment in
            HStack {
                Text("Parcela \(installment.installmentNumber)/\(plan.installmentCount)")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(installment.amount.currencyFormatted)
                    Text(installment.dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if installment.isPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .swipeActions {
                if !installment.isPaid {
                    Button("Paga") {
                        viewModel.markAsPaid(installment)
                    }
                    .tint(.green)
                }
            }
        }
        .navigationTitle(plan.title)
    }
}
