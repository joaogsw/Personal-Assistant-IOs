import Foundation

/// The minimum information an `AIProvider` needs to interpret one message — never the
/// full database. Built fresh by `AssistantOrchestrator` for every turn.
struct AssistantContext {
    let currentDate: Date
    let timeZoneIdentifier: String
    let localeIdentifier: String
    let availableShoppingLists: [String]
    let allowedExpenseCategories: [String]
    let knownPaymentMethods: [String]

    /// Renders context + the user's message as the single user-turn string sent to the
    /// provider. Kept here (not in `AssistantSystemPrompt`) because it's per-request data,
    /// not shared instructions.
    func renderedUserMessage(input: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let currentDateString = formatter.string(from: currentDate)

        var lines: [String] = []
        lines.append("Contexto:")
        lines.append("- Data e hora atuais: \(currentDateString)")
        lines.append("- Fuso horário: \(timeZoneIdentifier)")
        lines.append("- Locale: \(localeIdentifier)")
        lines.append("- Categorias de despesa permitidas: \(allowedExpenseCategories.joined(separator: ", "))")
        lines.append("- Formas de pagamento conhecidas: \(knownPaymentMethods.joined(separator: ", "))")
        if availableShoppingLists.isEmpty {
            lines.append("- Listas de compras existentes: nenhuma ainda")
        } else {
            lines.append("- Listas de compras existentes: \(availableShoppingLists.joined(separator: ", "))")
        }
        lines.append("")
        lines.append("Mensagem do usuário:")
        lines.append(input)
        return lines.joined(separator: "\n")
    }
}
