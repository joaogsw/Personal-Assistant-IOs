import Foundation

struct AssistantExecutionResult: Equatable {
    let message: String
}

enum AssistantOrchestratorError: Error {
    case entityNotFound(String)
}

/// Coordinates the future end-to-end flow:
/// user input -> AIProvider -> StructuredAction -> ActionValidator -> repositories -> SwiftData.
/// The AI is never the source of truth and never writes to persistence directly;
/// it only proposes an action that must pass validation first.
final class AssistantOrchestrator {
    private let aiProvider: AIProvider
    private let validator: ActionValidator
    private let expenseRepository: ExpenseRepository
    private let installmentRepository: InstallmentRepository
    private let recurringBillRepository: RecurringBillRepository
    private let taskRepository: TaskRepository
    private let reminderRepository: ReminderRepository
    private let shoppingListRepository: ShoppingListRepository

    init(
        aiProvider: AIProvider,
        expenseRepository: ExpenseRepository,
        installmentRepository: InstallmentRepository,
        recurringBillRepository: RecurringBillRepository,
        taskRepository: TaskRepository,
        reminderRepository: ReminderRepository,
        shoppingListRepository: ShoppingListRepository,
        validator: ActionValidator = ActionValidator()
    ) {
        self.aiProvider = aiProvider
        self.expenseRepository = expenseRepository
        self.installmentRepository = installmentRepository
        self.recurringBillRepository = recurringBillRepository
        self.taskRepository = taskRepository
        self.reminderRepository = reminderRepository
        self.shoppingListRepository = shoppingListRepository
        self.validator = validator
    }

    func handle(_ userInput: String) async throws -> AssistantExecutionResult {
        let action = try await aiProvider.interpret(userInput)
        let validated = try validator.validate(action)
        return try execute(validated)
    }

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

        case .completeTask(let taskID, let taskTitle):
            let tasks = try taskRepository.fetchAll()
            guard let task = tasks.first(where: { matches($0.id, $0.title, taskID, taskTitle) }) else {
                throw AssistantOrchestratorError.entityNotFound("task")
            }
            try taskRepository.complete(task)
            try taskRepository.save()
            return AssistantExecutionResult(message: "Tarefa \"\(task.title)\" concluída.")

        case .markBillAsPaid(let billID, let billTitle):
            let bills = try recurringBillRepository.fetchAll()
            guard let bill = bills.first(where: { matches($0.id, $0.title, billID, billTitle) }) else {
                throw AssistantOrchestratorError.entityNotFound("recurringBill")
            }
            try recurringBillRepository.markAsPaid(bill)
            try recurringBillRepository.save()
            return AssistantExecutionResult(message: "Conta \"\(bill.title)\" marcada como paga.")

        case .queryData(let question):
            // Etapa 2: delegate to a query engine over the local data. For now, just acknowledge.
            return AssistantExecutionResult(message: "Consulta recebida: \"\(question)\". Respostas automáticas serão implementadas em uma etapa futura.")
        }
    }

    private func matches(_ id: UUID, _ title: String, _ targetID: UUID?, _ targetTitle: String?) -> Bool {
        if let targetID {
            return id == targetID
        }
        if let targetTitle {
            return title.caseInsensitiveCompare(targetTitle) == .orderedSame
        }
        return false
    }
}
