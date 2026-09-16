import SwiftUI

struct TodayView: View {
    @State var viewModel: TodayViewModel

    private var hasNoPendingItems: Bool {
        viewModel.summary.tasksDueToday.isEmpty
            && viewModel.summary.billsDueToday.isEmpty
            && viewModel.summary.upcoming.isEmpty
            && viewModel.summary.remindersToday.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Resumo") {
                    LabeledContent("Tarefas pendentes", value: "\(viewModel.summary.pendingTasksCount)")
                    LabeledContent("Total a vencer hoje", value: viewModel.summary.totalDueTodayAmount.currencyFormatted)
                }

                if !viewModel.summary.tasksDueToday.isEmpty {
                    Section("Tarefas de hoje") {
                        ForEach(viewModel.summary.tasksDueToday) { task in
                            HStack {
                                Text(task.title)
                                Spacer()
                                Text(task.priority.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !viewModel.summary.billsDueToday.isEmpty {
                    Section("Vence hoje") {
                        ForEach(viewModel.summary.billsDueToday) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                Text(item.amount.currencyFormatted)
                            }
                        }
                    }
                }

                if !viewModel.summary.upcoming.isEmpty {
                    Section("Próximos vencimentos") {
                        ForEach(viewModel.summary.upcoming) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.amount.currencyFormatted)
                                    Text(item.dueDate, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !viewModel.summary.remindersToday.isEmpty {
                    Section("Lembretes de hoje") {
                        ForEach(viewModel.summary.remindersToday) { reminder in
                            Text(reminder.title)
                        }
                    }
                }

                if hasNoPendingItems {
                    EmptyStateView(
                        systemImage: "checkmark.circle",
                        title: "Tudo em dia",
                        message: "Você não tem pendências para hoje."
                    )
                }
            }
            .navigationTitle("Hoje")
            .task { viewModel.load() }
            .refreshable { viewModel.load() }
        }
    }
}
