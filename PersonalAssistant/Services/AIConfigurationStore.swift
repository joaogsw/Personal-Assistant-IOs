import Foundation

/// Persists the (non-secret) `AIConfiguration` — provider, model, temperature, maxTokens.
/// The API key itself never lives here; it's Keychain-only (see `KeychainService`).
protocol AIConfigurationStoring {
    func load() -> AIConfiguration
    func save(_ configuration: AIConfiguration)
}

final class AIConfigurationStore: AIConfigurationStoring {
    private let defaults: UserDefaults
    private let key = "assistant.aiConfiguration"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AIConfiguration {
        guard let data = defaults.data(forKey: key),
              let configuration = try? JSONDecoder().decode(AIConfiguration.self, from: data) else {
            return .default
        }
        return configuration
    }

    func save(_ configuration: AIConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: key)
    }
}
