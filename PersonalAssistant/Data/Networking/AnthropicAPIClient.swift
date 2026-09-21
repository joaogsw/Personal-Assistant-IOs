import Foundation
import os

private let logger = Logger(subsystem: "com.joaogsw.PersonalAssistant", category: "AnthropicAPIClient")

/// Failure reasons specific to talking to the Anthropic API. Kept private to the Data
/// layer — `AnthropicAIProvider` translates these into the provider-agnostic
/// `AIProviderError` before anything in Domain ever sees them.
enum AnthropicAPIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingFailed
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Nenhuma chave de API configurada."
        case .invalidResponse:
            return "Resposta inesperada do servidor de IA."
        case .httpError(let statusCode, let message):
            return "Erro de comunicação com a IA (\(statusCode))\(message.map { ": \($0)" } ?? "")."
        case .decodingFailed:
            return "Não foi possível interpretar a resposta da IA."
        case .network(let underlying):
            return "Falha de rede ao contatar a IA: \(underlying.localizedDescription)"
        }
    }
}

/// Talks only HTTP to the Anthropic Messages API (`POST /v1/messages`) using
/// `output_config.format` (structured outputs) so the response text is guaranteed to be
/// schema-valid JSON. Knows nothing about `StructuredAction`, repositories, or the
/// assistant pipeline — `AnthropicAIProvider` owns that translation. No third-party
/// dependency: plain `URLSession`.
final class AnthropicAPIClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns the raw JSON text of Claude's first text content block. Callers decode it
    /// against their own schema-matching type.
    func createMessage(
        apiKey: String,
        model: String,
        maxTokens: Int,
        system: String,
        userMessage: String,
        jsonSchema: [String: Any],
        effort: String = "low"
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AnthropicAPIError.missingAPIKey
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var format: [String: Any] = [:]
        format["type"] = "json_schema"
        format["schema"] = jsonSchema

        var outputConfig: [String: Any] = [:]
        outputConfig["effort"] = effort
        outputConfig["format"] = format

        var message: [String: Any] = [:]
        message["role"] = "user"
        message["content"] = userMessage

        // Sampling params (temperature/top_p/top_k) are intentionally omitted: Claude
        // Opus 5 / Sonnet 5 reject them with an HTTP 400. `output_config.effort` is the
        // current mechanism for controlling depth/cost instead.
        var body: [String: Any] = [:]
        body["model"] = model
        body["max_tokens"] = maxTokens
        body["system"] = system
        body["messages"] = [message]
        body["output_config"] = outputConfig

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AnthropicAPIError.network(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("Network request failed: \(error.localizedDescription, privacy: .public)")
            throw AnthropicAPIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicAPIError.invalidResponse
        }

        logger.debug("Anthropic API responded with status \(httpResponse.statusCode, privacy: .public)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.extractErrorMessage(from: data)
            throw AnthropicAPIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let decoded = try? JSONDecoder().decode(MessagesAPIResponse.self, from: data),
              let textBlock = decoded.content.first(where: { $0.type == "text" }),
              let text = textBlock.text else {
            throw AnthropicAPIError.decodingFailed
        }

        return text
    }

    private static func extractErrorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }
}

private struct MessagesAPIResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}
