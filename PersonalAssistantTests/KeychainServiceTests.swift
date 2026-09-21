import Foundation
import Testing
@testable import PersonalAssistant

/// Exercises the `KeychainServicing` contract via the in-memory double. The real
/// `KeychainService` implements the exact same protocol against the Security framework;
/// these behavioral guarantees (save/read/overwrite/delete/missing-key) are what the rest
/// of the app depends on regardless of which implementation is behind the protocol.
struct KeychainServiceTests {
    @Test func readingMissingKeyReturnsNil() throws {
        let keychain = InMemoryKeychainService()
        #expect(try keychain.readString(forKey: "missing") == nil)
    }

    @Test func savingThenReadingReturnsTheSameValue() throws {
        let keychain = InMemoryKeychainService()
        try keychain.saveString("sk-ant-12345", forKey: AssistantKeychainKey.anthropicAPIKey)
        #expect(try keychain.readString(forKey: AssistantKeychainKey.anthropicAPIKey) == "sk-ant-12345")
    }

    @Test func savingTwiceOverwritesThePreviousValue() throws {
        let keychain = InMemoryKeychainService()
        try keychain.saveString("first-key", forKey: AssistantKeychainKey.anthropicAPIKey)
        try keychain.saveString("second-key", forKey: AssistantKeychainKey.anthropicAPIKey)
        #expect(try keychain.readString(forKey: AssistantKeychainKey.anthropicAPIKey) == "second-key")
    }

    @Test func deletingRemovesTheValue() throws {
        let keychain = InMemoryKeychainService()
        try keychain.saveString("sk-ant-12345", forKey: AssistantKeychainKey.anthropicAPIKey)
        try keychain.deleteValue(forKey: AssistantKeychainKey.anthropicAPIKey)
        #expect(try keychain.readString(forKey: AssistantKeychainKey.anthropicAPIKey) == nil)
    }

    @Test func deletingAMissingKeyDoesNotThrow() throws {
        let keychain = InMemoryKeychainService()
        try keychain.deleteValue(forKey: "never-saved")
    }
}
