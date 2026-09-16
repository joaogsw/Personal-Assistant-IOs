import Foundation

/// Abstracts persistence for `Reminder`.
protocol ReminderRepository {
    func fetchAll() throws -> [Reminder]
    func insert(_ reminder: Reminder) throws
    func delete(_ reminder: Reminder) throws
    func complete(_ reminder: Reminder) throws
    func save() throws
}
