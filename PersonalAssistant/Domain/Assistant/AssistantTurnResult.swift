import Foundation

/// A validated action awaiting user confirmation before it reaches a repository.
struct PendingAction: Identifiable {
    let id: UUID
    let action: ValidatedAction
    let summary: String

    init(id: UUID = UUID(), action: ValidatedAction, summary: String) {
        self.id = id
        self.action = action
        self.summary = summary
    }
}

/// Result of one turn of the assistant conversation: what the assistant said, what ran
/// immediately, and what is still waiting on the user to confirm or cancel.
struct AssistantTurnResult {
    let message: String
    let executed: [AssistantExecutionResult]
    let pendingActions: [PendingAction]
    let needsClarification: Bool
    let clarificationQuestion: String?
    let warnings: [String]
}
