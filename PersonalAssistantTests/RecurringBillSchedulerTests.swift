import Foundation
import Testing
@testable import PersonalAssistant

struct RecurringBillSchedulerTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func advancesMonthlyBillByOneMonth() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = RecurringBillScheduler.nextDueDate(after: date, recurrence: .monthly, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.year == 2026)
        #expect(components.month == 4)
        #expect(components.day == 10)
    }

    @Test func advancesMonthlyBillAcrossYearBoundary() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 12, day: 10))!
        let next = RecurringBillScheduler.nextDueDate(after: date, recurrence: .monthly, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.year == 2027)
        #expect(components.month == 1)
        #expect(components.day == 10)
    }

    @Test func clampsMonthlyBillDayForShorterMonth() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let next = RecurringBillScheduler.nextDueDate(after: date, recurrence: .monthly, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }

    @Test func advancesWeeklyBillBySevenDays() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = RecurringBillScheduler.nextDueDate(after: date, recurrence: .weekly, calendar: calendar)
        let daysBetween = calendar.dateComponents([.day], from: date, to: next).day
        #expect(daysBetween == 7)
    }

    @Test func advancesYearlyBillAndClampsLeapDay() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        let next = RecurringBillScheduler.nextDueDate(after: date, recurrence: .yearly, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.year == 2025)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }
}
