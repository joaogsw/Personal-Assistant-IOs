import Foundation
import Observation

@MainActor
@Observable
final class InstallmentsViewModel {
    private let repository: InstallmentRepository

    var plans: [InstallmentPlan] = []
    var errorMessage: String?

    init(repository: InstallmentRepository) {
        self.repository = repository
    }

    func load() {
        do {
            plans = try repository.fetchAllPlans()
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar as compras parceladas."
        }
    }

    func addInstallmentPurchase(
        title: String,
        totalAmount: Decimal,
        installmentCount: Int,
        firstInstallmentDate: Date,
        paymentMethod: PaymentMethod
    ) {
        let plan = InstallmentPlanGenerator.generate(
            title: title,
            totalAmount: totalAmount,
            installmentCount: installmentCount,
            firstInstallmentDate: firstInstallmentDate,
            paymentMethod: paymentMethod
        )
        do {
            try repository.insert(plan)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível salvar a compra parcelada."
        }
    }

    func markAsPaid(_ installment: Installment) {
        do {
            try repository.markAsPaid(installment)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível atualizar a parcela."
        }
    }

    func delete(_ plan: InstallmentPlan) {
        do {
            try repository.delete(plan)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível excluir a compra parcelada."
        }
    }
}
