import Foundation
import SwiftData

final class SwiftDataExpenseRepository: ExpenseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ expense: Expense) throws {
        context.insert(expense)
    }

    func delete(_ expense: Expense) throws {
        context.delete(expense)
    }

    func save() throws {
        try context.save()
    }
}
