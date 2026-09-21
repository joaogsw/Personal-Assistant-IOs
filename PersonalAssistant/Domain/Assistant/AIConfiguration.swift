import Foundation

enum AIProviderKind: String, Codable, CaseIterable, Identifiable {
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        }
    }
}

/// Centralizes which AI provider/model/parameters the app uses — the single place to
/// change when switching models, so no model identifier is hardcoded elsewhere.
///
/// Note: `temperature` is part of this app-level configuration for forward-compatibility
/// with providers that support it, but Claude Opus 5 / Sonnet 5 currently reject
/// `temperature`/`top_p`/`top_k` with an HTTP 400 (sampling params were removed on those
/// models). `AnthropicAIProvider` does not forward this field to the API; it uses
/// `output_config.effort` instead. See that file for details.
struct AIConfiguration: Codable, Equatable {
    var provider: AIProviderKind
    var model: String
    var temperature: Double
    var maxTokens: Int

    static let `default` = AIConfiguration(
        provider: .claude,
        model: "claude-opus-5",
        temperature: 0.2,
        maxTokens: 2048
    )
}

/// Well-known Keychain key for the Anthropic API key, shared by the provider and the
/// Settings screen so the name is never duplicated.
enum AssistantKeychainKey {
    static let anthropicAPIKey = "anthropic_api_key"
}
