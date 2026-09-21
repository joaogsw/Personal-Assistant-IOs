import Foundation

/// Decides which validated actions must be shown to the user for confirmation before
/// they touch persistence. Centralized here so the policy (e.g. "confirm every financial
/// action") can change later — say, only above a value threshold — without touching
/// `AssistantOrchestrator`.
protocol ActionConfirmationPolicy {
    func requiresConfirmation(for action: ValidatedAction) -> Bool
}

/// Financial actions (they create or settle money records) always require confirmation.
/// Tasks, reminders, and shopping-list edits execute immediately — matching the Etapa 2
/// spec's examples (adding shopping items or creating a task needs no confirmation card).
struct DefaultActionConfirmationPolicy: ActionConfirmationPolicy {
    func requiresConfirmation(for action: ValidatedAction) -> Bool {
        switch action {
        case .createExpense, .createInstallmentPurchase, .createRecurringBill,
             .markInstallmentAsPaid, .markRecurringBillAsPaid:
            return true
        case .createTask, .createReminder, .addShoppingItem, .completeTask, .queryData:
            return false
        }
    }
}
