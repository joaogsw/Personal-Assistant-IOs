import Foundation

/// Abstracts persistence for `Expense`. Views/ViewModels depend on this protocol only,
/// never on SwiftData directly, so the storage layer can be swapped later.
protocol ExpenseRepository {
    func fetchAll() throws -> [Expense]
    func insert(_ expense: Expense) throws
    func delete(_ expense: Expense) throws
    func save() throws
}
