import Foundation

enum ActionValidationError: LocalizedError, Equatable {
    case missingField(String)
    case invalidValue(String)

    var errorDescription: String? {
        switch self {
        case .missingField(let field): return "Campo obrigatório ausente: \(field)"
        case .invalidValue(let field): return "Valor inválido para: \(field)"
        }
    }
}

/// A `StructuredAction` after its fields have been checked and converted into
/// strongly-typed domain values. Only a `ValidatedAction` may reach the repositories —
/// the AI is never trusted to write to the database directly.
enum ValidatedAction {
    case createExpense(title: String, amount: Decimal, date: Date, category: ExpenseCategory, paymentMethod: PaymentMethod, notes: String?)
    case createInstallmentPurchase(title: String, totalAmount: Decimal, installmentCount: Int, firstInstallmentDate: Date, paymentMethod: PaymentMethod)
    case createRecurringBill(title: String, amount: Decimal, recurrence: RecurrenceFrequency, nextDueDate: Date, reminderDaysBefore: Int, category: ExpenseCategory)
    case createTask(title: String, notes: String?, dueDate: Date?, priority: TaskPriority)
    case createReminder(title: String, reminderDate: Date)
    case addShoppingItem(listTitle: String, itemName: String, quantity: Int?)
    case completeTask(taskID: UUID?, taskTitle: String?)
    case markBillAsPaid(billID: UUID?, billTitle: String?)
    case queryData(question: String)
}

struct ActionValidator {
    func validate(_ action: StructuredAction) throws -> ValidatedAction {
        switch action {
        case .createExpense(let payload):
            let title = try require(payload.title, field: "title")
            let amount = try requirePositive(payload.amount, field: "amount")
            let category = ExpenseCategory(rawValue: payload.category ?? "") ?? .other
            let paymentMethod = PaymentMethod(rawValue: payload.paymentMethod ?? "") ?? .other
            return .createExpense(
                title: title,
                amount: amount,
                date: payload.date ?? .now,
                category: category,
                paymentMethod: paymentMethod,
                notes: payload.notes
            )

        case .createInstallmentPurchase(let payload):
            let title = try require(payload.title, field: "title")
            let totalAmount = try requirePositive(payload.totalAmount, field: "totalAmount")
            let installmentCount = try require(payload.installmentCount, field: "installmentCount")
            guard installmentCount > 0 else { throw ActionValidationError.invalidValue("installmentCount") }
            let paymentMethod = PaymentMethod(rawValue: payload.paymentMethod ?? "") ?? .creditCard
            return .createInstallmentPurchase(
                title: title,
                totalAmount: totalAmount,
                installmentCount: installmentCount,
                firstInstallmentDate: payload.firstInstallmentDate ?? .now,
                paymentMethod: paymentMethod
            )

        case .createRecurringBill(let payload):
            let title = try require(payload.title, field: "title")
            let amount = try requirePositive(payload.amount, field: "amount")
            let recurrence = RecurrenceFrequency(rawValue: payload.recurrence ?? "") ?? .monthly
            let nextDueDate = try require(payload.nextDueDate, field: "nextDueDate")
            let category = ExpenseCategory(rawValue: payload.category ?? "") ?? .other
            return .createRecurringBill(
                title: title,
                amount: amount,
                recurrence: recurrence,
                nextDueDate: nextDueDate,
                reminderDaysBefore: payload.reminderDaysBefore ?? 0,
                category: category
            )

        case .createTask(let payload):
            let title = try require(payload.title, field: "title")
            let priority = TaskPriority(rawValue: payload.priority ?? "") ?? .medium
            return .createTask(title: title, notes: payload.notes, dueDate: payload.dueDate, priority: priority)

        case .createReminder(let payload):
            let title = try require(payload.title, field: "title")
            let reminderDate = try require(payload.reminderDate, field: "reminderDate")
            return .createReminder(title: title, reminderDate: reminderDate)

        case .addShoppingItem(let payload):
            let listTitle = try require(payload.listTitle, field: "listTitle")
            let itemName = try require(payload.itemName, field: "itemName")
            return .addShoppingItem(listTitle: listTitle, itemName: itemName, quantity: payload.quantity)

        case .completeTask(let payload):
            guard payload.taskID != nil || payload.taskTitle != nil else {
                throw ActionValidationError.missingField("taskID or taskTitle")
            }
            return .completeTask(taskID: payload.taskID, taskTitle: payload.taskTitle)

        case .markBillAsPaid(let payload):
            guard payload.billID != nil || payload.billTitle != nil else {
                throw ActionValidationError.missingField("billID or billTitle")
            }
            return .markBillAsPaid(billID: payload.billID, billTitle: payload.billTitle)

        case .queryData(let payload):
            let question = try require(payload.question, field: "question")
            return .queryData(question: question)
        }
    }

    private func require<T>(_ value: T?, field: String) throws -> T {
        guard let value else { throw ActionValidationError.missingField(field) }
        return value
    }

    private func requirePositive(_ value: Decimal?, field: String) throws -> Decimal {
        let unwrapped = try require(value, field: field)
        guard unwrapped > 0 else { throw ActionValidationError.invalidValue(field) }
        return unwrapped
    }
}
