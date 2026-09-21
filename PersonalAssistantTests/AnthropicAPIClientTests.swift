import Foundation
import Testing
@testable import PersonalAssistant

struct AnthropicAPIClientTests {
    private func makeClient() -> AnthropicAPIClient {
        AnthropicAPIClient(session: MockURLProtocol.makeSession())
    }

    private var schema: [String: Any] {
        var okProperty: [String: Any] = [:]
        okProperty["type"] = "boolean"

        var properties: [String: Any] = [:]
        properties["ok"] = okProperty

        var schema: [String: Any] = [:]
        schema["type"] = "object"
        schema["properties"] = properties
        schema["required"] = ["ok"]
        schema["additionalProperties"] = false
        return schema
    }

    @Test func successfulResponseReturnsTextBlock() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = #"{"content":[{"type":"text","text":"{\"ok\":true}"}]}"#
            return (response, Data(body.utf8))
        }

        let client = makeClient()
        let text = try await client.createMessage(
            apiKey: "sk-test",
            model: "claude-opus-5",
            maxTokens: 16,
            system: "system prompt",
            userMessage: "ping",
            jsonSchema: schema
        )

        #expect(text == "{\"ok\":true}")
    }

    @Test func httpErrorStatusThrowsWithServerMessage() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            let body = #"{"error":{"type":"authentication_error","message":"invalid x-api-key"}}"#
            return (response, Data(body.utf8))
        }

        let client = makeClient()

        await #expect(throws: AnthropicAPIError.self) {
            _ = try await client.createMessage(
                apiKey: "sk-invalid",
                model: "claude-opus-5",
                maxTokens: 16,
                system: "system prompt",
                userMessage: "ping",
                jsonSchema: schema
            )
        }
    }

    @Test func malformedResponseBodyThrowsDecodingFailed() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("not json at all".utf8))
        }

        let client = makeClient()

        await #expect(throws: AnthropicAPIError.self) {
            _ = try await client.createMessage(
                apiKey: "sk-test",
                model: "claude-opus-5",
                maxTokens: 16,
                system: "system prompt",
                userMessage: "ping",
                jsonSchema: schema
            )
        }
    }

    @Test func emptyAPIKeyThrowsWithoutMakingARequest() async throws {
        MockURLProtocol.requestHandler = { _ in
            Issue.record("Should not perform a request with an empty API key")
            throw URLError(.badURL)
        }

        let client = makeClient()

        await #expect(throws: AnthropicAPIError.self) {
            _ = try await client.createMessage(
                apiKey: "",
                model: "claude-opus-5",
                maxTokens: 16,
                system: "system prompt",
                userMessage: "ping",
                jsonSchema: schema
            )
        }
    }
}
