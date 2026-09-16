import Foundation

/// The set of commands the assistant will be able to propose once an `AIProvider` is
/// implemented. Payload fields are intentionally optional/loosely typed: the AI's
/// extraction may be partial, so `ActionValidator` is responsible for turning a
/// `StructuredAction` into a strongly-typed, safe-to-execute `ValidatedAction`.
/// This is not the final JSON schema — just enough shape to make the
/// AIProvider -> Validation -> Orchestrator -> Repository pipeline testable now.
enum StructuredAction {
    case createExpense(CreateExpensePayload)
    case createInstallmentPurchase(CreateInstallmentPurchasePayload)
    case createRecurringBill(CreateRecurringBillPayload)
    case createTask(CreateTaskPayload)
    case createReminder(CreateReminderPayload)
    case addShoppingItem(AddShoppingItemPayload)
    case completeTask(CompleteTaskPayload)
    case markBillAsPaid(MarkBillAsPaidPayload)
    case queryData(QueryDataPayload)
}

struct CreateExpensePayload: Codable {
    var title: String?
    var amount: Decimal?
    var date: Date?
    var category: String?
    var paymentMethod: String?
    var notes: String?
}

struct CreateInstallmentPurchasePayload: Codable {
    var title: String?
    var totalAmount: Decimal?
    var installmentCount: Int?
    var firstInstallmentDate: Date?
    var paymentMethod: String?
}

struct CreateRecurringBillPayload: Codable {
    var title: String?
    var amount: Decimal?
    var recurrence: String?
    var nextDueDate: Date?
    var reminderDaysBefore: Int?
    var category: String?
}

struct CreateTaskPayload: Codable {
    var title: String?
    var notes: String?
    var dueDate: Date?
    var priority: String?
}

struct CreateReminderPayload: Codable {
    var title: String?
    var reminderDate: Date?
}

struct AddShoppingItemPayload: Codable {
    var listTitle: String?
    var itemName: String?
    var quantity: Int?
}

struct CompleteTaskPayload: Codable {
    var taskID: UUID?
    var taskTitle: String?
}

struct MarkBillAsPaidPayload: Codable {
    var billID: UUID?
    var billTitle: String?
}

struct QueryDataPayload: Codable {
    var question: String?
}
