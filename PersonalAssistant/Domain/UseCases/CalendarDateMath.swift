import Foundation

/// Month/year arithmetic that clamps the day-of-month instead of overflowing into the
/// next month, so e.g. Jan 31 + 1 month lands on Feb 28 (or 29), never Mar 3.
/// `Calendar.date(byAdding:to:)` alone does not guarantee this, so both
/// `InstallmentPlanGenerator` and `RecurringBillScheduler` route through here.
enum CalendarDateMath {
    static func addingMonthsClamped(_ months: Int, to date: Date, calendar: Calendar = .current) -> Date {
        guard months != 0 else { return date }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return date
        }

        let totalMonths = (month - 1) + months
        let yearOffset = totalMonths >= 0 ? totalMonths / 12 : (totalMonths - 11) / 12
        let newYear = year + yearOffset
        let newMonth = totalMonths - yearOffset * 12 + 1

        var firstOfMonthComponents = DateComponents()
        firstOfMonthComponents.year = newYear
        firstOfMonthComponents.month = newMonth
        firstOfMonthComponents.day = 1

        guard let firstOfMonth = calendar.date(from: firstOfMonthComponents),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return date
        }

        var resultComponents = firstOfMonthComponents
        resultComponents.day = min(day, dayRange.upperBound - 1)
        resultComponents.hour = components.hour
        resultComponents.minute = components.minute
        resultComponents.second = components.second

        return calendar.date(from: resultComponents) ?? date
    }
}
