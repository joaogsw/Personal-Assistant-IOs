import Foundation

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case creditCard
    case debitCard
    case cash
    case pix
    case bankTransfer
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creditCard: return "Cartão de Crédito"
        case .debitCard: return "Cartão de Débito"
        case .cash: return "Dinheiro"
        case .pix: return "Pix"
        case .bankTransfer: return "Transferência"
        case .other: return "Outro"
        }
    }
}
