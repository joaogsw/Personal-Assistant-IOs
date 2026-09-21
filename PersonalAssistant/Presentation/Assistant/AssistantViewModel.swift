import Foundation
import Observation

struct ChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

/// Drives the "Assistente" chat screen. The chat transcript here is session-only — the
/// source of truth is always the structured data created through `AssistantOrchestrator`,
/// never this message history (see Etapa 2 privacy/architecture principles).
@MainActor
@Observable
final class AssistantViewModel {
    private let orchestrator: AssistantOrchestrator

    var messages: [ChatMessage] = []
    var pendingActions: [PendingAction] = []
    var inputText: String = ""
    var isLoading: Bool = false

    init(orchestrator: AssistantOrchestrator) {
        self.orchestrator = orchestrator
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, text: text))
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await orchestrator.handle(text)
            pendingActions.append(contentsOf: result.pendingActions)

            var responseLines: [String] = [result.message]
            responseLines.append(contentsOf: result.executed.map(\.message))
            responseLines.append(contentsOf: result.warnings)

            messages.append(ChatMessage(role: .assistant, text: responseLines.joined(separator: "\n")))
        } catch {
            messages.append(ChatMessage(role: .assistant, text: "Ocorreu um erro ao processar sua solicitação."))
        }
    }

    func confirm(_ pendingAction: PendingAction) async {
        pendingActions.removeAll { $0.id == pendingAction.id }
        do {
            let result = try orchestrator.confirm(pendingAction.id)
            messages.append(ChatMessage(role: .assistant, text: result.message))
        } catch {
            messages.append(ChatMessage(role: .assistant, text: "Essa ação já não está mais disponível."))
        }
    }

    func cancel(_ pendingAction: PendingAction) {
        pendingActions.removeAll { $0.id == pendingAction.id }
        orchestrator.cancel(pendingAction.id)
        messages.append(ChatMessage(role: .assistant, text: "Ação cancelada."))
    }
}
