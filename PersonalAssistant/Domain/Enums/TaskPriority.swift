import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable, Comparable {
    case low
    case medium
    case high

    var id: String { rawValue }

    private var sortWeight: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortWeight < rhs.sortWeight
    }

    var displayName: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        }
    }
}
