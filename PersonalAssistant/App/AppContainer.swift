import Foundation
import SwiftData

/// Manual dependency-injection container: builds the SwiftData `ModelContainer` and the
/// concrete repositories, then hands out repository *protocols* to the rest of the app.
/// Centralizing this here is also what will let us point the store at an App Group
/// container (for the future Widget) by changing this one place.
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer

    let expenseRepository: ExpenseRepository
    let installmentRepository: InstallmentRepository
    let recurringBillRepository: RecurringBillRepository
    let taskRepository: TaskRepository
    let reminderRepository: ReminderRepository
    let shoppingListRepository: ShoppingListRepository

    init(inMemory: Bool = false) {
        let schema = Schema([
            Expense.self,
            InstallmentPlan.self,
            Installment.self,
            RecurringBill.self,
            TaskItem.self,
            Reminder.self,
            ShoppingList.self,
            ShoppingListItem.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        let context = modelContainer.mainContext
        expenseRepository = SwiftDataExpenseRepository(context: context)
        installmentRepository = SwiftDataInstallmentRepository(context: context)
        recurringBillRepository = SwiftDataRecurringBillRepository(context: context)
        taskRepository = SwiftDataTaskRepository(context: context)
        reminderRepository = SwiftDataReminderRepository(context: context)
        shoppingListRepository = SwiftDataShoppingListRepository(context: context)
    }
}
