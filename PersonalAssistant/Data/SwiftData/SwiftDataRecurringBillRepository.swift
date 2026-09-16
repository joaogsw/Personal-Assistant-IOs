import Foundation
import SwiftData

final class SwiftDataRecurringBillRepository: RecurringBillRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func fetchAll() throws -> [RecurringBill] {
        let descriptor = FetchDescriptor<RecurringBill>(sortBy: [SortDescriptor(\.nextDueDate, order: .forward)])
        return try context.fetch(descriptor)
    }

    func insert(_ bill: RecurringBill) throws {
        context.insert(bill)
    }

    func delete(_ bill: RecurringBill) throws {
        context.delete(bill)
    }

    /// The model has no per-cycle payment history, so "marking as paid" advances
    /// `nextDueDate` to the following cycle via `RecurringBillScheduler`.
    func markAsPaid(_ bill: RecurringBill) throws {
        bill.nextDueDate = RecurringBillScheduler.nextDueDate(after: bill.nextDueDate, recurrence: bill.recurrence, calendar: calendar)
    }

    func save() throws {
        try context.save()
    }
}
