import Foundation

/// Test double for `AIProvider`. No real AI backend exists yet in this stage; this lets
/// `AssistantOrchestrator` be exercised end-to-end (without any network/API) both in unit
/// tests and, later, in SwiftUI previews.
final class MockAIProvider: AIProvider {
    enum MockError: Error {
        case noResponseQueued
    }

    private var queuedResponses: [Result<StructuredAction, Error>]
    private(set) var receivedInputs: [String] = []

    init(responses: [Result<StructuredAction, Error>] = []) {
        self.queuedResponses = responses
    }

    func enqueue(_ action: StructuredAction) {
        queuedResponses.append(.success(action))
    }

    func enqueue(error: Error) {
        queuedResponses.append(.failure(error))
    }

    func interpret(_ userInput: String) async throws -> StructuredAction {
        receivedInputs.append(userInput)
        guard !queuedResponses.isEmpty else { throw MockError.noResponseQueued }
        return try queuedResponses.removeFirst().get()
    }
}
