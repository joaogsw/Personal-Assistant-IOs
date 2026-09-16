import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case housing
    case food
    case transportation
    case health
    case education
    case leisure
    case shopping
    case subscriptions
    case utilities
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .housing: return "Moradia"
        case .food: return "Alimentação"
        case .transportation: return "Transporte"
        case .health: return "Saúde"
        case .education: return "Educação"
        case .leisure: return "Lazer"
        case .shopping: return "Compras"
        case .subscriptions: return "Assinaturas"
        case .utilities: return "Contas de Consumo"
        case .other: return "Outros"
        }
    }

    var systemImageName: String {
        switch self {
        case .housing: return "house.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .health: return "cross.case.fill"
        case .education: return "book.fill"
        case .leisure: return "gamecontroller.fill"
        case .shopping: return "bag.fill"
        case .subscriptions: return "arrow.triangle.2.circlepath"
        case .utilities: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
