import Foundation
import Testing
@testable import PersonalAssistant

struct InstallmentRepositoryTests {
    @Test func insertingPlanPersistsItsInstallments() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataInstallmentRepository(context: context)

        let plan = InstallmentPlanGenerator.generate(
            title: "Notebook",
            totalAmount: 3000,
            installmentCount: 3,
            firstInstallmentDate: .now,
            paymentMethod: .creditCard
        )

        try repository.insert(plan)
        try repository.save()

        let plans = try repository.fetchAllPlans()
        #expect(plans.count == 1)
        let installments = try repository.fetchAllInstallments()
        #expect(installments.count == 3)
    }

    @Test func markingInstallmentAsPaidSetsPaidAt() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataInstallmentRepository(context: context)

        let plan = InstallmentPlanGenerator.generate(
            title: "Notebook",
            totalAmount: 900,
            installmentCount: 3,
            firstInstallmentDate: .now,
            paymentMethod: .creditCard
        )
        try repository.insert(plan)
        try repository.save()

        let installment = try #require(plan.installments.first)
        try repository.markAsPaid(installment)
        try repository.save()

        #expect(installment.isPaid)
        #expect(installment.paidAt != nil)
    }
}
