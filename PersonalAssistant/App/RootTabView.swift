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

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
    }
}
