import Foundation

/// Entry point for Claude/OpenAI/on-device providers. An `AIProvider` only *interprets*
/// free-form text into a `StructuredAssistantResponse` — it never touches persistence
/// directly, never receives a `ModelContext`, and never executes anything itself.
/// `AnthropicAIProvider` is the current implementation; `MockAIProvider` is the test
/// double. Adding `OpenAIProvider`/`AppleFoundationModelsProvider`/`LocalAIProvider`
/// later requires no change to this protocol or to `AssistantOrchestrator`.
protocol AIProvider {
    func interpret(input: String, context: AssistantContext) async throws -> StructuredAssistantResponse
}

/// Provider-agnostic failure reasons `AssistantOrchestrator` can react to. Concrete
/// providers (e.g. `AnthropicAIProvider`) translate their own HTTP/decoding errors into
/// these cases so Domain never depends on a networking type.
enum AIProviderError: LocalizedError {
    case notImplemented
    case missingAPIKey
    case requestFailed(String)
    case decodingFailed
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Este provedor de IA ainda não está implementado."
        case .missingAPIKey:
            return "Nenhuma chave de API configurada. Adicione sua chave em Ajustes > Inteligência Artificial."
        case .requestFailed(let message):
            return message.isEmpty ? "Não foi possível falar com a IA agora." : "Não foi possível falar com a IA agora: \(message)."
        case .decodingFailed:
            return "Não consegui interpretar essa solicitação com segurança. Tente novamente."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
