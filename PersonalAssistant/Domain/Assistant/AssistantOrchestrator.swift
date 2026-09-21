import Foundation
import os

struct AssistantExecutionResult: Equatable {
    let message: String
}

enum AssistantOrchestratorError: LocalizedError {
    case entityNotFound(String)
    case pendingActionNotFound

    var errorDescription: String? {
        switch self {
        case .entityNotFound(let kind):
            return "Não encontrei \(displayName(for: kind)) com esse nome."
        case .pendingActionNotFound:
            return "Essa ação já não está mais disponível para confirmação."
        }
    }

    private func displayName(for kind: String) -> String {
        switch kind {
        case "task": return "uma tarefa"
        case "installmentPlan": return "uma compra parcelada"
        case "installment": return "uma parcela em aberto"
        case "recurringBill": return "uma conta recorrente"
        default: return "esse item"
        }
    }
}

private let logger = Logger(subsystem: "com.joaogsw.PersonalAssistant", category: "AssistantOrchestrator")

/// Coordinates the full flow:
/// user input -> AssistantContext -> AIProvider -> StructuredAssistantResponse ->
/// ActionValidator -> (confirmation policy) -> repositories -> SwiftData.
///
/// The AI is never the source of truth and never writes to persistence directly: it only
/// proposes actions, which must pass validation, and financial actions must additionally
/// wait for the user to confirm a `PendingAction` via `confirm(_:)`. `AssistantOrchestrator`
/// itself never touches HTTP — that's `AIProvider`'s job.
@MainActor
final class AssistantOrchestrator {
    private let aiProvider: AIProvider
    private let validator: ActionValidator
    private let confirmationPolicy: ActionConfirmationPolicy
    private let dateProvider: DateProviding

    private let expenseRepository: ExpenseRepository
    private let installmentRepository: InstallmentRepository
    private let recurringBillRepository: RecurringBillRepository
    private let taskRepository: TaskRepository
    private let reminderRepository: ReminderRepository
    private let shoppingListRepository: ShoppingListRepository

    /// Actions awaiting user confirmation, keyed by `PendingAction.id`. Removing an entry
    /// here on `confirm`/`cancel` is what makes a duplicate confirmation tap a no-op
    /// (the second call finds nothing and throws `.pendingActionNotFound`) instead of a
    /// second write.
    private var pendingActionsByID: [UUID: ValidatedAction] = [:]

    init(
        aiProvider: AIProvider,
        expenseRepository: ExpenseRepository,
        installmentRepository: InstallmentRepository,
        recurringBillRepository: RecurringBillRepository,
        taskRepository: TaskRepository,
        reminderRepository: ReminderRepository,
        shoppingListRepository: ShoppingListRepository,
        validator: ActionValidator = ActionValidator(),
        confirmationPolicy: ActionConfirmationPolicy = DefaultActionConfirmationPolicy(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.aiProvider = aiProvider
        self.expenseRepository = expenseRepository
        self.installmentRepository = installmentRepository
        self.recurringBillRepository = recurringBillRepository
        self.taskRepository = taskRepository
        self.reminderRepository = reminderRepository
        self.shoppingListRepository = shoppingListRepository
        self.validator = validator
        self.confirmationPolicy = confirmationPolicy
        self.dateProvider = dateProvider
    }

    // MARK: - Turn handling

    func handle(_ userInput: String) async throws -> AssistantTurnResult {
        let context = buildContext()

        let response: StructuredAssistantResponse
        do {
            response = try await aiProvider.interpret(input: userInput, context: context)
        } catch {
            logger.error("AIProvider failed: \(String(describing: error), privacy: .public)")
            return AssistantTurnResult(
                message: friendlyMessage(for: error),
                executed: [],
                pendingActions: [],
                needsClarification: false,
                clarificationQuestion: nil,
                warnings: []
            )
        }

        if response.needsClarification {
            return AssistantTurnResult(
                message: response.clarificationQuestion ?? response.message,
                executed: [],
                pendingActions: [],
                needsClarification: true,
                clarificationQuestion: response.clarificationQuestion,
                warnings: response.warnings
            )
        }

        var executed: [AssistantExecutionResult] = []
        var pending: [PendingAction] = []
        var warnings = response.warnings

        for action in response.actions {
            let validated: ValidatedAction
            do {
                validated = try validator.validate(action)
            } catch {
                logger.error("Action failed validation: \(String(describing: error), privacy: .public)")
                warnings.append(friendlyMessage(for: error))
                continue
            }

            if confirmationPolicy.requiresConfirmation(for: validated) {
                if let preview = buildPendingAction(for: validated) {
                    pending.append(preview)
                } else {
                    warnings.append("Não encontrei os dados necessários para confirmar essa ação.")
                }
            } else {
                do {
                    executed.append(try execute(validated))
                } catch {
                    logger.error("Action failed execution: \(String(describing: error), privacy: .public)")
                    warnings.append(friendlyMessage(for: error))
                }
            }
        }

        for pendingAction in pending {
            pendingActionsByID[pendingAction.id] = pendingAction.action
        }

        return AssistantTurnResult(
            message: response.message,
            executed: executed,
            pendingActions: pending,
            needsClarification: false,
            clarificationQuestion: nil,
            warnings: warnings
        )
    }

    /// Executes a previously staged action. Throws `.pendingActionNotFound` if it was
    /// already confirmed, already canceled, or never existed — the caller should treat
    /// that as a safe no-op rather than a hard failure.
    func confirm(_ pendingActionID: UUID) throws -> AssistantExecutionResult {
        guard let action = pendingActionsByID.removeValue(forKey: pendingActionID) else {
            throw AssistantOrchestratorError.pendingActionNotFound
        }
        return try execute(action)
    }

    func cancel(_ pendingActionID: UUID) {
        pendingActionsByID.removeValue(forKey: pendingActionID)
    }

    // MARK: - Context

    private func buildContext() -> AssistantContext {
        let shoppingLists = (try? shoppingListRepository.fetchAllLists().map(\.title)) ?? []
        return AssistantContext(
            currentDate: dateProvider.now(),
            timeZoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier,
            availableShoppingLists: shoppingLists,
            allowedExpenseCategories: ExpenseCategory.allCases.map(\.rawValue),
            knownPaymentMethods: PaymentMethod.allCases.map(\.rawValue)
        )
    }

    // MARK: - Pending action previews

    private func buildPendingAction(for action: ValidatedAction) -> PendingAction? {
        switch action {
        case .createExpense(let title, let amount, let date, let category, let paymentMethod, _):
            let summary = [
                title,
                amount.currencyFormatted,
                "\(category.displayName) • \(paymentMethod.displayName)",
                date.formatted(date: .abbreviated, time: .omitted)
            ].joined(separator: "\n")
            return PendingAction(action: action, summary: summary)

        case .createInstallmentPurchase(let title, let totalAmount, let installmentCount, _, let paymentMethod):
            let each = totalAmount / Decimal(installmentCount)
            let summary = [
                title,
                totalAmount.currencyFormatted,
                "\(installmentCount)x de \(each.currencyFormatted)",
                paymentMethod.displayName
            ].joined(separator: "\n")
            return PendingAction(action: action, summary: summary)

        case .createRecurringBill(let title, let amount, let recurrence, let nextDueDate, _, let category):
            let summary = [
                title,
                "\(amount.currencyFormatted) • \(recurrence.displayName)",
                "Próximo vencimento: \(nextDueDate.formatted(date: .abbreviated, time: .omitted))",
                category.displayName
            ].joined(separator: "\n")
            return PendingAction(action: action, summary: summary)

        case .markInstallmentAsPaid(let planTitle, let installmentNumber):
            guard let (plan, installment) = try? resolveInstallment(planTitle: planTitle, installmentNumber: installmentNumber) else {
                return nil
            }
            let summary = [
                "Marcar parcela \(installment.installmentNumber) de \"\(plan.title)\" como paga",
                installment.amount.currencyFormatted
            ].joined(separator: "\n")
            return PendingAction(action: action, summary: summary)

        case .markRecurringBillAsPaid(let billTitle):
            guard let bill = try? resolveRecurringBill(title: billTitle) else {
                return nil
            }
            let summary = [
                "Marcar \"\(bill.title)\" como paga",
                bill.amount.currencyFormatted
            ].joined(separator: "\n")
            return PendingAction(action: action, summary: summary)

        case .createTask, .createReminder, .addShoppingItem, .completeTask, .queryData:
            // These never require confirmation (see DefaultActionConfirmationPolicy),
            // so this branch is unreachable in practice.
            return nil
        }
    }

    // MARK: - Execution

    private func execute(_ action: ValidatedAction) throws -> AssistantExecutionResult {
        switch action {
        case .createExpense(let title, let amount, let date, let category, let paymentMethod, let notes):
            let expense = Expense(title: title, amount: amount, date: date, category: category, paymentMethod: paymentMethod, notes: notes)
            try expenseRepository.insert(expense)
            try expenseRepository.save()
            return AssistantExecutionResult(message: "Despesa \"\(title)\" registrada.")

        case .createInstallmentPurchase(let title, let totalAmount, let installmentCount, let firstInstallmentDate, let paymentMethod):
            let plan = InstallmentPlanGenerator.generate(
                title: title,
                totalAmount: totalAmount,
                installmentCount: installmentCount,
                firstInstallmentDate: firstInstallmentDate,
                paymentMethod: paymentMethod
            )
            try installmentRepository.insert(plan)
            try installmentRepository.save()
            return AssistantExecutionResult(message: "Compra parcelada \"\(title)\" registrada em \(installmentCount)x.")

        case .createRecurringBill(let title, let amount, let recurrence, let nextDueDate, let reminderDaysBefore, let category):
            let bill = RecurringBill(title: title, amount: amount, recurrence: recurrence, nextDueDate: nextDueDate, reminderDaysBefore: reminderDaysBefore, category: category)
            try recurringBillRepository.insert(bill)
            try recurringBillRepository.save()
            return AssistantExecutionResult(message: "Conta recorrente \"\(title)\" cadastrada.")

        case .createTask(let title, let notes, let dueDate, let priority):
            let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority)
            try taskRepository.insert(task)
            try taskRepository.save()
            return AssistantExecutionResult(message: "Tarefa \"\(title)\" criada.")

        case .createReminder(let title, let reminderDate):
            let reminder = Reminder(title: title, reminderDate: reminderDate)
            try reminderRepository.insert(reminder)
            try reminderRepository.save()
            return AssistantExecutionResult(message: "Lembrete \"\(title)\" criado.")

        case .addShoppingItem(let listTitle, let itemName, let quantity):
            let lists = try shoppingListRepository.fetchAllLists()
            let list = lists.first { $0.title.caseInsensitiveCompare(listTitle) == .orderedSame }
                ?? {
                    let newList = ShoppingList(title: listTitle)
                    try? shoppingListRepository.insert(newList)
                    return newList
                }()
            let item = ShoppingListItem(name: itemName, quantity: quantity, list: list)
            try shoppingListRepository.addItem(item, to: list)
            try shoppingListRepository.save()
            return AssistantExecutionResult(message: "\"\(itemName)\" adicionado à lista \"\(list.title)\".")

        case .completeTask(let taskTitle):
            let tasks = try taskRepository.fetchAll()
            guard let task = tasks.first(where: { !$0.isCompleted && $0.title.caseInsensitiveCompare(taskTitle) == .orderedSame }) else {
                throw AssistantOrchestratorError.entityNotFound("task")
            }
            try taskRepository.complete(task)
            try taskRepository.save()
            return AssistantExecutionResult(message: "Tarefa \"\(task.title)\" concluída.")

        case .markInstallmentAsPaid(let planTitle, let installmentNumber):
            let (plan, installment) = try resolveInstallment(planTitle: planTitle, installmentNumber: installmentNumber)
            try installmentRepository.markAsPaid(installment)
            try installmentRepository.save()
            return AssistantExecutionResult(message: "Parcela \(installment.installmentNumber) de \"\(plan.title)\" marcada como paga.")

        case .markRecurringBillAsPaid(let billTitle):
            let bill = try resolveRecurringBill(title: billTitle)
            try recurringBillRepository.markAsPaid(bill)
            try recurringBillRepository.save()
            return AssistantExecutionResult(message: "Conta \"\(bill.title)\" marcada como paga.")

        case .queryData(let question):
            // Etapa 3: delegate to a query engine over the local data. For now, just acknowledge.
            return AssistantExecutionResult(message: "Consulta recebida: \"\(question)\". Respostas automáticas serão implementadas em uma etapa futura.")
        }
    }

    // MARK: - Resolution helpers

    private func resolveInstallment(planTitle: String, installmentNumber: Int?) throws -> (InstallmentPlan, Installment) {
        let plans = try installmentRepository.fetchAllPlans()
        guard let plan = plans.first(where: { $0.title.caseInsensitiveCompare(planTitle) == .orderedSame }) else {
            throw AssistantOrchestratorError.entityNotFound("installmentPlan")
        }

        let installment: Installment?
        if let installmentNumber {
            installment = plan.installments.first { $0.installmentNumber == installmentNumber }
        } else {
            installment = plan.installments
                .filter { !$0.isPaid }
                .sorted { $0.installmentNumber < $1.installmentNumber }
                .first
        }

        guard let resolvedInstallment = installment else {
            throw AssistantOrchestratorError.entityNotFound("installment")
        }
        return (plan, resolvedInstallment)
    }

    private func resolveRecurringBill(title: String) throws -> RecurringBill {
        let bills = try recurringBillRepository.fetchAll()
        guard let bill = bills.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) else {
            throw AssistantOrchestratorError.entityNotFound("recurringBill")
        }
        return bill
    }

    // MARK: - Error presentation

    private func friendlyMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return "Não consegui interpretar essa solicitação com segurança. Tente novamente."
    }
}
