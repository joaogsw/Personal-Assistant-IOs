import Foundation
import Testing
@testable import PersonalAssistant

struct ActionValidatorTests {
    private let validator = ActionValidator()

    private func expectMissingField(_ field: String, when action: StructuredAction) {
        do {
            _ = try validator.validate(action)
            Issue.record("Expected validation to throw for missing field \(field)")
        } catch let error as ActionValidationError {
            #expect(error == .missingField(field))
        } catch {
            Issue.record("Expected ActionValidationError, got \(error)")
        }
    }

    private func expectInvalidValue(_ field: String, when action: StructuredAction) {
        do {
            _ = try validator.validate(action)
            Issue.record("Expected validation to throw for invalid field \(field)")
        } catch let error as ActionValidationError {
            #expect(error == .invalidValue(field))
        } catch {
            Issue.record("Expected ActionValidationError, got \(error)")
        }
    }

    @Test func createExpenseWithMissingTitleThrowsMissingField() {
        expectMissingField("title", when: .createExpense(CreateExpensePayload(title: nil, amount: 80)))
    }

    @Test func createExpenseWithZeroAmountThrowsInvalidValue() {
        expectInvalidValue("amount", when: .createExpense(CreateExpensePayload(title: "Mercado", amount: 0)))
    }

    @Test func createExpenseWithUnknownCategoryFallsBackToOther() throws {
        let action = StructuredAction.createExpense(
            CreateExpensePayload(title: "Mercado", amount: 80, category: "not-a-real-category")
        )
        let validated = try validator.validate(action)
        guard case .createExpense(_, _, _, let category, _, _) = validated else {
            Issue.record("Expected createExpense")
            return
        }
        #expect(category == .other)
    }

    @Test func createInstallmentPurchaseRequiresMoreThanOneInstallment() {
        expectInvalidValue(
            "installmentCount",
            when: .createInstallmentPurchase(CreateInstallmentPurchasePayload(title: "TV", totalAmount: 3000, installmentCount: 1))
        )
    }

    @Test func createRecurringBillRequiresNextDueDate() {
        expectMissingField(
            "nextDueDate",
            when: .createRecurringBill(CreateRecurringBillPayload(title: "Academia", amount: 150, recurrence: "monthly"))
        )
    }

    @Test func addShoppingItemRequiresNonEmptyItemName() {
        expectMissingField(
            "itemName",
            when: .addShoppingItem(AddShoppingItemPayload(listTitle: "Mercado", itemName: "   "))
        )
    }

    @Test func completeTaskRequiresTaskTitle() {
        expectMissingField("taskTitle", when: .completeTask(CompleteTaskPayload(taskTitle: nil)))
    }

    @Test func markInstallmentAsPaidAllowsNilInstallmentNumber() throws {
        let action = StructuredAction.markInstallmentAsPaid(
            MarkInstallmentAsPaidPayload(installmentPlanTitle: "Notebook", installmentNumber: nil)
        )
        let validated = try validator.validate(action)
        guard case .markInstallmentAsPaid(let planTitle, let number) = validated else {
            Issue.record("Expected markInstallmentAsPaid")
            return
        }
        #expect(planTitle == "Notebook")
        #expect(number == nil)
    }

    @Test func markInstallmentAsPaidRejectsNonPositiveInstallmentNumber() {
        expectInvalidValue(
            "installmentNumber",
            when: .markInstallmentAsPaid(MarkInstallmentAsPaidPayload(installmentPlanTitle: "Notebook", installmentNumber: 0))
        )
    }

    @Test func markRecurringBillAsPaidRequiresBillTitle() {
        expectMissingField("billTitle", when: .markRecurringBillAsPaid(MarkRecurringBillAsPaidPayload(billTitle: nil)))
    }
}
