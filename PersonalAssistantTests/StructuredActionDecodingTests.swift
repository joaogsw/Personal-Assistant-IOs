import Foundation
import Testing
@testable import PersonalAssistant

struct StructuredActionDecodingTests {
    private func decodeResponse(_ json: String) throws -> StructuredAssistantResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StructuredAssistantResponse.self, from: Data(json.utf8))
    }

    @Test func decodesCreateExpenseFromFlatDiscriminatedJSON() throws {
        let json = """
        {
          "message": "Registrei sua despesa.",
          "needsClarification": false,
          "clarificationQuestion": null,
          "warnings": [],
          "actions": [
            {
              "type": "createExpense",
              "title": "Mercado",
              "amount": 80,
              "date": "2026-09-22T00:00:00-03:00",
              "category": "food",
              "paymentMethod": "creditCard",
              "notes": null
            }
          ]
        }
        """

        let response = try decodeResponse(json)

        #expect(response.actions.count == 1)
        guard case .createExpense(let payload) = response.actions[0] else {
            Issue.record("Expected createExpense action")
            return
        }
        #expect(payload.title == "Mercado")
        #expect(payload.amount == 80)
        #expect(payload.category == "food")
    }

    @Test func decodesMultipleActionsOfDifferentTypes() throws {
        let json = """
        {
          "message": "Adicionei os itens.",
          "needsClarification": false,
          "clarificationQuestion": null,
          "warnings": [],
          "actions": [
            {"type": "addShoppingItem", "listTitle": "Mercado", "itemName": "Leite", "quantity": null},
            {"type": "addShoppingItem", "listTitle": "Mercado", "itemName": "Café", "quantity": null}
          ]
        }
        """

        let response = try decodeResponse(json)
        #expect(response.actions.count == 2)

        guard case .addShoppingItem(let first) = response.actions[0],
              case .addShoppingItem(let second) = response.actions[1] else {
            Issue.record("Expected two addShoppingItem actions")
            return
        }
        #expect(first.itemName == "Leite")
        #expect(second.itemName == "Café")
    }

    @Test func decodesClarificationResponseWithEmptyActions() throws {
        let json = """
        {
          "message": "Preciso de mais informações.",
          "needsClarification": true,
          "clarificationQuestion": "Qual é o dia de vencimento da academia?",
          "warnings": [],
          "actions": []
        }
        """

        let response = try decodeResponse(json)
        #expect(response.needsClarification)
        #expect(response.clarificationQuestion == "Qual é o dia de vencimento da academia?")
        #expect(response.actions.isEmpty)
    }

    @Test func decodesMarkInstallmentAsPaidWithNullInstallmentNumber() throws {
        let json = """
        {
          "message": "Ok.",
          "needsClarification": false,
          "clarificationQuestion": null,
          "warnings": [],
          "actions": [
            {"type": "markInstallmentAsPaid", "installmentPlanTitle": "Notebook", "installmentNumber": null}
          ]
        }
        """

        let response = try decodeResponse(json)
        guard case .markInstallmentAsPaid(let payload) = response.actions[0] else {
            Issue.record("Expected markInstallmentAsPaid action")
            return
        }
        #expect(payload.installmentPlanTitle == "Notebook")
        #expect(payload.installmentNumber == nil)
    }

    @Test func unknownActionTypeThrowsInsteadOfExecutingUnsafeData() {
        let json = """
        {
          "message": "x",
          "needsClarification": false,
          "clarificationQuestion": null,
          "warnings": [],
          "actions": [
            {"type": "deleteEverything", "title": "x"}
          ]
        }
        """

        #expect(throws: (any Error).self) {
            try decodeResponse(json)
        }
    }
}
