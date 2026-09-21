import Foundation

/// Test double for `AIProvider`. Lets `AssistantOrchestrator` (and SwiftUI previews) be
/// exercised end-to-end without any network call — queue up canned responses and inspect
/// what was received.
final class MockAIProvider: AIProvider {
    enum MockError: Error {
        case noResponseQueued
    }

    private var queuedResponses: [Result<StructuredAssistantResponse, Error>]
    private(set) var receivedInputs: [String] = []
    private(set) var receivedContexts: [AssistantContext] = []

    init(responses: [Result<StructuredAssistantResponse, Error>] = []) {
        self.queuedResponses = responses
    }

    func enqueue(_ response: StructuredAssistantResponse) {
        queuedResponses.append(.success(response))
    }

    func enqueue(actions: [StructuredAction], message: String = "") {
        queuedResponses.append(.success(
            StructuredAssistantResponse(
                message: message,
                actions: actions,
                needsClarification: false,
                clarificationQuestion: nil,
                warnings: []
            )
        ))
    }

    func enqueue(clarification question: String, message: String = "") {
        queuedResponses.append(.success(
            StructuredAssistantResponse(
                message: message,
                actions: [],
                needsClarification: true,
                clarificationQuestion: question,
                warnings: []
            )
        ))
    }

    func enqueue(error: Error) {
        queuedResponses.append(.failure(error))
    }

    func interpret(input: String, context: AssistantContext) async throws -> StructuredAssistantResponse {
        receivedInputs.append(input)
        receivedContexts.append(context)
        guard !queuedResponses.isEmpty else { throw MockError.noResponseQueued }
        return try queuedResponses.removeFirst().get()
    }
}
