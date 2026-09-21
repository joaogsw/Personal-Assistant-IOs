import SwiftUI

struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            TodayView(
                viewModel: TodayViewModel(
                    taskRepository: container.taskRepository,
                    recurringBillRepository: container.recurringBillRepository,
                    installmentRepository: container.installmentRepository,
                    reminderRepository: container.reminderRepository
                )
            )
            .tabItem { Label("Hoje", systemImage: "sun.max.fill") }

            AssistantView(viewModel: AssistantViewModel(orchestrator: container.assistantOrchestrator))
                .tabItem { Label("Assistente", systemImage: "bubble.left.and.bubble.right.fill") }

            FinancesView(
                expenseRepository: container.expenseRepository,
                installmentRepository: container.installmentRepository,
                recurringBillRepository: container.recurringBillRepository
            )
            .tabItem { Label("Finanças", systemImage: "dollarsign.circle.fill") }

            TasksView(viewModel: TasksViewModel(repository: container.taskRepository))
                .tabItem { Label("Tarefas", systemImage: "checkmark.circle.fill") }

            ShoppingListsView(viewModel: ShoppingListsViewModel(repository: container.shoppingListRepository))
                .tabItem { Label("Listas", systemImage: "cart.fill") }

            SettingsView(
                keychainService: container.keychainService,
                aiConfigurationStore: container.aiConfigurationStore
            )
            .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
    }
}
