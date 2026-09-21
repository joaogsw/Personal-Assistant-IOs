import Foundation
@testable import PersonalAssistant

/// In-memory stand-in for `KeychainService`, so tests never touch the real Keychain
/// (which may require entitlements/simulator state that aren't guaranteed in a test
/// bundle) while still exercising the exact `KeychainServicing` contract the app relies on.
final class InMemoryKeychainService: KeychainServicing {
    private var storage: [String: String] = [:]

    func readString(forKey key: String) throws -> String? {
        storage[key]
    }

    func saveString(_ value: String, forKey key: String) throws {
        storage[key] = value
    }

    func deleteValue(forKey key: String) throws {
        storage.removeValue(forKey: key)
    }
}
