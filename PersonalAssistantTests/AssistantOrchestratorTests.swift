import Foundation
import SwiftData
import Testing
@testable import PersonalAssistant

@MainActor
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

    // MARK: - Financial actions require confirmation

    @Test func financialActionIsStagedAsPendingNotExecutedImmediately() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createExpense(CreateExpensePayload(title: "Camisa", amount: 400, category: "shopping", paymentMethod: "creditCard"))
        ], message: "Entendi, confirme para registrar.")
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")

        #expect(result.pendingActions.count == 1)
        #expect(result.executed.isEmpty)
        #expect(try SwiftDataExpenseRepository(context: context).fetchAll().isEmpty)
    }

    @Test func confirmingPendingExpensePersistsIt() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createExpense(CreateExpensePayload(title: "Camisa", amount: 400, category: "shopping", paymentMethod: "creditCard"))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")
        let pending = try #require(result.pendingActions.first)

        let executionResult = try orchestrator.confirm(pending.id)

        #expect(executionResult.message.contains("Camisa"))
        let expenses = try SwiftDataExpenseRepository(context: context).fetchAll()
        #expect(expenses.count == 1)
    }

    @Test func confirmingInstallmentPurchaseUsesInstallmentPlanGenerator() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createInstallmentPurchase(CreateInstallmentPurchasePayload(
                title: "TV",
                totalAmount: 3000,
                installmentCount: 10,
                firstInstallmentDate: .now,
                paymentMethod: "creditCard"
            ))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma TV por R$ 3.000 em 10 vezes no BTG.")
        let pending = try #require(result.pendingActions.first)
        #expect(pending.summary.contains("10x"))

        _ = try orchestrator.confirm(pending.id)

        let plans = try SwiftDataInstallmentRepository(context: context).fetchAllPlans()
        #expect(plans.count == 1)
        #expect(plans.first?.installments.count == 10)
    }

    @Test func confirmingRecurringBillPersistsIt() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createRecurringBill(CreateRecurringBillPayload(
                title: "Academia",
                amount: 150,
                recurrence: "monthly",
                nextDueDate: .now,
                category: "health"
            ))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Minha academia custa R$ 150 por mês, vence todo dia 10.")
        let pending = try #require(result.pendingActions.first)
        _ = try orchestrator.confirm(pending.id)

        let bills = try SwiftDataRecurringBillRepository(context: context).fetchAll()
        #expect(bills.count == 1)
        #expect(bills.first?.title == "Academia")
    }

    // MARK: - Non-financial actions execute immediately

    @Test func createTaskExecutesImmediatelyWithoutConfirmation() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createTask(CreateTaskPayload(title: "Ligar para Felipe", dueDate: .now, priority: "medium"))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Tenho que ligar para o Felipe amanhã às 14h.")

        #expect(result.pendingActions.isEmpty)
        #expect(result.executed.count == 1)
        let tasks = try SwiftDataTaskRepository(context: context).fetchAll()
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "Ligar para Felipe")
    }

    @Test func multipleShoppingItemsInOneTurnAreAllAdded() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .addShoppingItem(AddShoppingItemPayload(listTitle: "Mercado", itemName: "Leite")),
            .addShoppingItem(AddShoppingItemPayload(listTitle: "Mercado", itemName: "Café"))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Adiciona leite e café na lista Mercado.")

        #expect(result.executed.count == 2)
        let lists = try SwiftDataShoppingListRepository(context: context).fetchAllLists()
        #expect(lists.count == 1)
        #expect(lists.first?.items.count == 2)
    }

    // MARK: - Clarification

    @Test func missingCriticalFieldTriggersClarificationWithoutCreatingAnything() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(clarification: "Qual é o dia de vencimento da academia?")
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Registra minha academia.")

        #expect(result.needsClarification)
        #expect(result.clarificationQuestion == "Qual é o dia de vencimento da academia?")
        #expect(result.pendingActions.isEmpty)
        #expect(result.executed.isEmpty)
        #expect(try SwiftDataRecurringBillRepository(context: context).fetchAll().isEmpty)
    }

    // MARK: - Invalid actions are skipped, not executed

    @Test func actionFailingValidationIsSkippedWithWarningAndNothingPersists() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createExpense(CreateExpensePayload(title: nil, amount: 400))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("despesa sem título")

        #expect(result.pendingActions.isEmpty)
        #expect(result.executed.isEmpty)
        #expect(!result.warnings.isEmpty)
        #expect(try SwiftDataExpenseRepository(context: context).fetchAll().isEmpty)
    }

    // MARK: - Cancellation and duplicate-confirmation protection

    @Test func cancelingPendingActionPreventsExecution() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createExpense(CreateExpensePayload(title: "Camisa", amount: 400))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")
        let pending = try #require(result.pendingActions.first)

        orchestrator.cancel(pending.id)

        #expect(throws: AssistantOrchestratorError.self) {
            try orchestrator.confirm(pending.id)
        }
        #expect(try SwiftDataExpenseRepository(context: context).fetchAll().isEmpty)
    }

    @Test func confirmingTwiceOnlyPersistsOnce() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .createExpense(CreateExpensePayload(title: "Camisa", amount: 400))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")
        let pending = try #require(result.pendingActions.first)

        _ = try orchestrator.confirm(pending.id)

        #expect(throws: AssistantOrchestratorError.self) {
            try orchestrator.confirm(pending.id)
        }

        let expenses = try SwiftDataExpenseRepository(context: context).fetchAll()
        #expect(expenses.count == 1)
    }

    // MARK: - Provider failure surfaces as a safe message, never a crash or partial write

    @Test func missingAPIKeyReturnsSafeMessageWithoutCreatingAnything() async throws {
        let context = TestModelContainerFactory.makeContext()
        let aiProvider = MockAIProvider()
        aiProvider.enqueue(error: AIProviderError.missingAPIKey)
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Comprei uma camisa de R$ 400")

        #expect(!result.message.isEmpty)
        #expect(result.pendingActions.isEmpty)
        #expect(result.executed.isEmpty)
        #expect(try SwiftDataExpenseRepository(context: context).fetchAll().isEmpty)
    }

    // MARK: - Mark as paid

    @Test func markInstallmentAsPaidWithoutNumberMarksEarliestUnpaidOne() async throws {
        let context = TestModelContainerFactory.makeContext()
        let installmentRepository = SwiftDataInstallmentRepository(context: context)
        let plan = InstallmentPlanGenerator.generate(
            title: "Notebook",
            totalAmount: 3000,
            installmentCount: 3,
            firstInstallmentDate: .now,
            paymentMethod: .creditCard
        )
        try installmentRepository.insert(plan)
        try installmentRepository.save()

        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .markInstallmentAsPaid(MarkInstallmentAsPaidPayload(installmentPlanTitle: "Notebook", installmentNumber: nil))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Paguei a parcela do notebook.")
        let pending = try #require(result.pendingActions.first)
        _ = try orchestrator.confirm(pending.id)

        let installments = try installmentRepository.fetchAllInstallments()
        #expect(installments.first { $0.installmentNumber == 1 }?.isPaid == true)
        #expect(installments.filter(\.isPaid).count == 1)
    }

    @Test func markRecurringBillAsPaidAdvancesNextDueDate() async throws {
        let context = TestModelContainerFactory.makeContext()
        let billRepository = SwiftDataRecurringBillRepository(context: context)
        let bill = RecurringBill(title: "Aluguel", amount: 2000, recurrence: .monthly, nextDueDate: .now, category: .housing)
        try billRepository.insert(bill)
        try billRepository.save()

        let aiProvider = MockAIProvider()
        aiProvider.enqueue(actions: [
            .markRecurringBillAsPaid(MarkRecurringBillAsPaidPayload(billTitle: "Aluguel"))
        ])
        let orchestrator = makeOrchestrator(context: context, aiProvider: aiProvider)

        let result = try await orchestrator.handle("Paguei o aluguel.")
        let pending = try #require(result.pendingActions.first)
        _ = try orchestrator.confirm(pending.id)

        #expect(bill.nextDueDate > Date())
    }
}
