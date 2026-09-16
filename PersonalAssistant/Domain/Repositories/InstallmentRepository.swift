import Foundation

/// Abstracts persistence for `InstallmentPlan` and its child `Installment` entries.
protocol InstallmentRepository {
    func fetchAllPlans() throws -> [InstallmentPlan]
    func fetchAllInstallments() throws -> [Installment]
    func insert(_ plan: InstallmentPlan) throws
    func delete(_ plan: InstallmentPlan) throws
    func markAsPaid(_ installment: Installment) throws
    func save() throws
}
