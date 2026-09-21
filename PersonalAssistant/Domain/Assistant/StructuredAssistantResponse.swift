import Foundation

/// What the AI is allowed to return. Only `actions` can ever change persisted data, and
/// only after `ActionValidator` accepts them — `message`/`warnings`/`clarificationQuestion`
/// are display-only text.
struct StructuredAssistantResponse: Decodable {
    let message: String
    let actions: [StructuredAction]
    let needsClarification: Bool
    let clarificationQuestion: String?
    let warnings: [String]
}

extension StructuredAssistantResponse {
    /// JSON Schema sent to the API via `output_config.format` so the model's response is
    /// guaranteed to decode into this type (Anthropic structured outputs). Every property
    /// is `required`; optional fields are expressed as nullable types rather than omitted,
    /// which is the reliable pattern for strict-schema decoding.
    ///
    /// Built with explicit `[String: Any]` locals and one subscript assignment per key,
    /// rather than one large nested literal — Swift's dictionary-literal type inference
    /// rejects literals that mix value types (String, Bool, nested Dictionary/Array) in a
    /// single expression without an explicit annotation, and this schema mixes them a lot.
    static var jsonSchema: [String: Any] {
        var stringProperty: [String: Any] = [:]
        stringProperty["type"] = "string"

        var booleanProperty: [String: Any] = [:]
        booleanProperty["type"] = "boolean"

        var warningsProperty: [String: Any] = [:]
        warningsProperty["type"] = "array"
        warningsProperty["items"] = stringProperty

        var actionsProperty: [String: Any] = [:]
        actionsProperty["type"] = "array"
        var actionItems: [String: Any] = [:]
        actionItems["anyOf"] = actionSchemas
        actionsProperty["items"] = actionItems

        var properties: [String: Any] = [:]
        properties["message"] = stringProperty
        properties["needsClarification"] = booleanProperty
        properties["clarificationQuestion"] = nullable(.string)
        properties["warnings"] = warningsProperty
        properties["actions"] = actionsProperty

        var schema: [String: Any] = [:]
        schema["type"] = "object"
        schema["properties"] = properties
        schema["required"] = ["message", "needsClarification", "clarificationQuestion", "warnings", "actions"]
        schema["additionalProperties"] = false
        return schema
    }

    private enum PrimitiveType: String {
        case string, integer, number, boolean
    }

    private static func nullable(_ type: PrimitiveType, format: String? = nil) -> [String: Any] {
        var typed: [String: Any] = [:]
        typed["type"] = type.rawValue
        if let format {
            typed["format"] = format
        }

        var nullType: [String: Any] = [:]
        nullType["type"] = "null"

        var result: [String: Any] = [:]
        result["anyOf"] = [typed, nullType]
        return result
    }

    private static func actionSchema(type: String, properties: [String: Any]) -> [String: Any] {
        var allProperties = properties
        var typeConst: [String: Any] = [:]
        typeConst["const"] = type
        allProperties["type"] = typeConst

        var schema: [String: Any] = [:]
        schema["type"] = "object"
        schema["properties"] = allProperties
        schema["required"] = Array(allProperties.keys)
        schema["additionalProperties"] = false
        return schema
    }

    private static var actionSchemas: [[String: Any]] {
        [
            actionSchema(type: "createExpense", properties: [
                "title": nullable(.string),
                "amount": nullable(.number),
                "date": nullable(.string, format: "date-time"),
                "category": nullable(.string),
                "paymentMethod": nullable(.string),
                "notes": nullable(.string)
            ]),
            actionSchema(type: "createInstallmentPurchase", properties: [
                "title": nullable(.string),
                "totalAmount": nullable(.number),
                "installmentCount": nullable(.integer),
                "firstInstallmentDate": nullable(.string, format: "date-time"),
                "paymentMethod": nullable(.string)
            ]),
            actionSchema(type: "createRecurringBill", properties: [
                "title": nullable(.string),
                "amount": nullable(.number),
                "recurrence": nullable(.string),
                "nextDueDate": nullable(.string, format: "date-time"),
                "reminderDaysBefore": nullable(.integer),
                "category": nullable(.string)
            ]),
            actionSchema(type: "createTask", properties: [
                "title": nullable(.string),
                "notes": nullable(.string),
                "dueDate": nullable(.string, format: "date-time"),
                "priority": nullable(.string)
            ]),
            actionSchema(type: "createReminder", properties: [
                "title": nullable(.string),
                "reminderDate": nullable(.string, format: "date-time")
            ]),
            actionSchema(type: "addShoppingItem", properties: [
                "listTitle": nullable(.string),
                "itemName": nullable(.string),
                "quantity": nullable(.integer)
            ]),
            actionSchema(type: "completeTask", properties: [
                "taskTitle": nullable(.string)
            ]),
            actionSchema(type: "markInstallmentAsPaid", properties: [
                "installmentPlanTitle": nullable(.string),
                "installmentNumber": nullable(.integer)
            ]),
            actionSchema(type: "markRecurringBillAsPaid", properties: [
                "billTitle": nullable(.string)
            ]),
            actionSchema(type: "queryData", properties: [
                "question": nullable(.string)
            ])
        ]
    }
}
