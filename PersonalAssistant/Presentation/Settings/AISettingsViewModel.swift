import Foundation
import Observation

@MainActor
@Observable
final class AISettingsViewModel {
    enum ConnectionTestState: Equatable {
        case idle
        case testing
        case success(String)
        case failure(String)
    }

    private let keychainService: KeychainServicing
    private let configurationStore: AIConfigurationStoring
    private let apiClient: AnthropicAPIClient

    var apiKeyInput: String = ""
    var hasStoredKey: Bool = false
    var connectionTestState: ConnectionTestState = .idle
    var statusMessage: String?

    var configuration: AIConfiguration {
        configurationStore.load()
    }

    init(
        keychainService: KeychainServicing,
        configurationStore: AIConfigurationStoring,
        apiClient: AnthropicAPIClient = AnthropicAPIClient()
    ) {
        self.keychainService = keychainService
        self.configurationStore = configurationStore
        self.apiClient = apiClient
        refreshStoredKeyStatus()
    }

    func refreshStoredKeyStatus() {
        let stored: String? = (try? keychainService.readString(forKey: AssistantKeychainKey.anthropicAPIKey)) ?? nil
        hasStoredKey = !(stored ?? "").isEmpty
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Informe uma chave antes de salvar."
            return
        }
        do {
            try keychainService.saveString(trimmed, forKey: AssistantKeychainKey.anthropicAPIKey)
            apiKeyInput = ""
            statusMessage = "Chave salva com segurança no Keychain."
            connectionTestState = .idle
            refreshStoredKeyStatus()
        } catch {
            statusMessage = "Não foi possível salvar a chave."
        }
    }

    func removeAPIKey() {
        do {
            try keychainService.deleteValue(forKey: AssistantKeychainKey.anthropicAPIKey)
            statusMessage = "Chave removida."
            connectionTestState = .idle
            refreshStoredKeyStatus()
        } catch {
            statusMessage = "Não foi possível remover a chave."
        }
    }

    func testConnection() async {
        connectionTestState = .testing

        let stored: String? = (try? keychainService.readString(forKey: AssistantKeychainKey.anthropicAPIKey)) ?? nil
        guard let apiKey = stored, !apiKey.isEmpty else {
            connectionTestState = .failure("Nenhuma chave configurada.")
            return
        }

        var okProperty: [String: Any] = [:]
        okProperty["type"] = "boolean"

        var properties: [String: Any] = [:]
        properties["ok"] = okProperty

        var pingSchema: [String: Any] = [:]
        pingSchema["type"] = "object"
        pingSchema["properties"] = properties
        pingSchema["required"] = ["ok"]
        pingSchema["additionalProperties"] = false

        do {
            _ = try await apiClient.createMessage(
                apiKey: apiKey,
                model: configuration.model,
                maxTokens: 16,
                system: "Responda apenas com o JSON {\"ok\": true}, nada mais.",
                userMessage: "ping",
                jsonSchema: pingSchema,
                effort: "low"
            )
            connectionTestState = .success("Conexão bem-sucedida.")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Falha na conexão."
            connectionTestState = .failure(message)
        }
    }
}
