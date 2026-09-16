import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Semanal"
        case .monthly: return "Mensal"
        case .yearly: return "Anual"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
}
