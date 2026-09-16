import Foundation

/// Computes the next due date for a recurring bill. Pure logic, no persistence.
enum RecurringBillScheduler {
    static func nextDueDate(after date: Date, recurrence: RecurrenceFrequency, calendar: Calendar = .current) -> Date {
        switch recurrence {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return CalendarDateMath.addingMonthsClamped(1, to: date, calendar: calendar)
        case .yearly:
            return CalendarDateMath.addingMonthsClamped(12, to: date, calendar: calendar)
        }
    }
}
