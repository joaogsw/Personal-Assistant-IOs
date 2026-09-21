import Foundation

/// The set of commands the assistant can propose. Payload fields are intentionally
/// optional: the AI's extraction may be partial, so `ActionValidator` is responsible for
/// turning a `StructuredAction` into a strongly-typed, safe-to-execute `ValidatedAction`.
/// The AI is never trusted to write to the database directly — it only ever proposes one
/// of these cases, decoded from a schema-constrained API response (see
/// `StructuredAssistantResponse.jsonSchema`).
enum StructuredAction {
    case createExpense(CreateExpensePayload)
    case createInstallmentPurchase(CreateInstallmentPurchasePayload)
    case createRecurringBill(CreateRecurringBillPayload)
    case createTask(CreateTaskPayload)
    case createReminder(CreateReminderPayload)
    case addShoppingItem(AddShoppingItemPayload)
    case completeTask(CompleteTaskPayload)
    case markInstallmentAsPaid(MarkInstallmentAsPaidPayload)
    case markRecurringBillAsPaid(MarkRecurringBillAsPaidPayload)
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
    var taskTitle: String?
}

struct MarkInstallmentAsPaidPayload: Codable {
    var installmentPlanTitle: String?
    /// When omitted, the app marks the plan's earliest unpaid installment.
    var installmentNumber: Int?
}

struct MarkRecurringBillAsPaidPayload: Codable {
    var billTitle: String?
}

struct QueryDataPayload: Codable {
    var question: String?
}

/// Decodes a flat JSON object discriminated by a `"type"` string field (e.g.
/// `{"type": "createExpense", "title": "...", "amount": 80, ...}`) into the matching
/// case. This mirrors the shape `StructuredAssistantResponse.jsonSchema` constrains the
/// API response to — a discriminator field alongside the action's own fields, not a
/// case-name-keyed wrapper.
extension StructuredAction: Decodable {
    private enum TypeCodingKey: String, CodingKey {
        case type
    }

    private enum ActionType: String, Decodable {
        case createExpense
        case createInstallmentPurchase
        case createRecurringBill
        case createTask
        case createReminder
        case addShoppingItem
        case completeTask
        case markInstallmentAsPaid
        case markRecurringBillAsPaid
        case queryData
    }

    init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeCodingKey.self)
        let type = try typeContainer.decode(ActionType.self, forKey: .type)
        let payloadContainer = try decoder.singleValueContainer()

        switch type {
        case .createExpense:
            self = .createExpense(try payloadContainer.decode(CreateExpensePayload.self))
        case .createInstallmentPurchase:
            self = .createInstallmentPurchase(try payloadContainer.decode(CreateInstallmentPurchasePayload.self))
        case .createRecurringBill:
            self = .createRecurringBill(try payloadContainer.decode(CreateRecurringBillPayload.self))
        case .createTask:
            self = .createTask(try payloadContainer.decode(CreateTaskPayload.self))
        case .createReminder:
            self = .createReminder(try payloadContainer.decode(CreateReminderPayload.self))
        case .addShoppingItem:
            self = .addShoppingItem(try payloadContainer.decode(AddShoppingItemPayload.self))
        case .completeTask:
            self = .completeTask(try payloadContainer.decode(CompleteTaskPayload.self))
        case .markInstallmentAsPaid:
            self = .markInstallmentAsPaid(try payloadContainer.decode(MarkInstallmentAsPaidPayload.self))
        case .markRecurringBillAsPaid:
            self = .markRecurringBillAsPaid(try payloadContainer.decode(MarkRecurringBillAsPaidPayload.self))
        case .queryData:
            self = .queryData(try payloadContainer.decode(QueryDataPayload.self))
        }
    }
}
