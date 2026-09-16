import Foundation
import SwiftData
@testable import PersonalAssistant

enum TestModelContainerFactory {
    static func makeContext() -> ModelContext {
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
