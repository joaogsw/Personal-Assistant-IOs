import Foundation
import SwiftData

final class SwiftDataInstallmentRepository: InstallmentRepository {
    private let context: ModelContext
    private let dateProvider: DateProviding

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider()) {
        self.context = context
        self.dateProvider = dateProvider
    }

    func fetchAllPlans() throws -> [InstallmentPlan] {
        let descriptor = FetchDescriptor<InstallmentPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchAllInstallments() throws -> [Installment] {
        let descriptor = FetchDescriptor<Installment>(sortBy: [SortDescriptor(\.dueDate, order: .forward)])
        return try context.fetch(descriptor)
    }

    func insert(_ plan: InstallmentPlan) throws {
        context.insert(plan)
        for installment in plan.installments {
            context.insert(installment)
        }
    }

    func delete(_ plan: InstallmentPlan) throws {
        context.delete(plan)
    }

    func markAsPaid(_ installment: Installment) throws {
        installment.isPaid = true
        installment.paidAt = dateProvider.now()
    }

    func save() throws {
        try context.save()
    }
}
