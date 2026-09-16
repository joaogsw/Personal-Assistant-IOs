import Foundation
import SwiftData
import Testing
@testable import PersonalAssistant

struct AssistantOrchestratorTests {
    private func makeOrchestrator(context: ModelContext, aiProvider: MockAIProvider) -> AssistantOrchestrator {
        AssistantOrchestrator(
            aiProvider: aiProvider,
            expenseRepository: SwiftDataExpenseRepository(context: context),
            installmentRepository: SwiftDataInstallmentRepository(context: context),
            recurringBillRepository: SwiftDataRecurringBillRepository(context: context),
            taskRepository: SwiftDataTaskRepository(context: context),
            reminderRepository: SwiftDataReminderRepository(context: context),
            shoppingListRepository: SwiftDataShoppingListRepository(context: context)
        )
    }

    @Test func validActionCreatesExpenseThroughRepository() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(
            .createExpense(
                CreateExpensePayload(title: "Camisa", amount: 400, category: "shopping", paymentMethod: "creditCard")
            )
        )
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")

        #expect(result.message.contains("Camisa"))
        let expenses = try SwiftDataExpenseRepository(context: context).fetchAll()
        #expect(expenses.count == 1)
    }

    @Test func invalidActionIsRejectedBeforeTouchingPersistence() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(.createExpense(CreateExpensePayload(title: nil, amount: 400)))
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        await #expect(throws: ActionValidationError.self) {
            try await orchestrator.handle("despesa sem título")
        }

        let expenses = try SwiftDataExpenseRepository(context: context).fetchAll()
        #expect(expenses.isEmpty)
    }
}
