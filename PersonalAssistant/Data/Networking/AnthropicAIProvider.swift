import Foundation

/// `AIProvider` implementation backed by the Anthropic Messages API. Reads the API key
/// and model configuration fresh on every call (never cached at init), so a key or model
/// change in Settings takes effect on the very next message without recreating this
/// object. This is the only place in the app that knows the Anthropic wire format.
final class AnthropicAIProvider: AIProvider {
    private let apiClient: AnthropicAPIClient
    private let keychainService: KeychainServicing
    private let configurationStore: AIConfigurationStoring

    init(
        apiClient: AnthropicAPIClient = AnthropicAPIClient(),
        keychainService: KeychainServicing,
        configurationStore: AIConfigurationStoring
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.configurationStore = configurationStore
    }

    func interpret(input: String, context: AssistantContext) async throws -> StructuredAssistantResponse {
        let apiKey: String?
        do {
            apiKey = try keychainService.readString(forKey: AssistantKeychainKey.anthropicAPIKey)
        } catch {
            throw AIProviderError.underlying(error)
        }

        guard let apiKey, !apiKey.isEmpty else {
            throw AIProviderError.missingAPIKey
        }

        let configuration = configurationStore.load()
        let userMessage = context.renderedUserMessage(input: input)

        let text: String
        do {
            text = try await apiClient.createMessage(
                apiKey: apiKey,
                model: configuration.model,
                maxTokens: configuration.maxTokens,
                system: AssistantSystemPrompt.text,
                userMessage: userMessage,
                jsonSchema: StructuredAssistantResponse.jsonSchema
            )
        } catch let error as AnthropicAPIError {
            throw Self.mapError(error)
        }

        guard let data = text.data(using: .utf8) else {
            throw AIProviderError.decodingFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(StructuredAssistantResponse.self, from: data)
        } catch {
            throw AIProviderError.decodingFailed
        }
    }

    private static func mapError(_ error: AnthropicAPIError) -> AIProviderError {
        switch error {
        case .missingAPIKey:
            return .missingAPIKey
        case .decodingFailed, .invalidResponse:
            return .decodingFailed
        case .httpError(_, let message):
            return .requestFailed(message ?? "")
        case .network:
            return .requestFailed("")
        }
    }
}
