import Foundation

/// Abstracts persistence for `RecurringBill`.
protocol RecurringBillRepository {
    func fetchAll() throws -> [RecurringBill]
    func insert(_ bill: RecurringBill) throws
    func delete(_ bill: RecurringBill) throws
    func markAsPaid(_ bill: RecurringBill) throws
    func save() throws
}
