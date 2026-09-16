import Foundation

/// Future entry point for Claude/OpenAI/on-device providers. An `AIProvider` only
/// *interprets* free-form text into a `StructuredAction` — it never touches
/// persistence directly. No concrete implementation exists yet in this stage.
protocol AIProvider {
    func interpret(_ userInput: String) async throws -> StructuredAction
}

enum AIProviderError: Error {
    case notImplemented
    case underlying(Error)
}
