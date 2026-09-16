import Foundation
import Testing
@testable import PersonalAssistant

struct TodaySummaryBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func includesTaskDueTodayAndExcludesCompletedOrFutureTasks() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let todayTask = TaskItem(title: "Hoje", dueDate: today, priority: .medium)
        let completedTask = TaskItem(title: "Concluída", dueDate: today, isCompleted: true, priority: .high)
        let futureTask = TaskItem(title: "Futura", dueDate: calendar.date(byAdding: .day, value: 3, to: today), priority: .low)

        let summary = TodaySummaryBuilder.build(
            tasks: [todayTask, completedTask, futureTask],
            recurringBills: [],
            installments: [],
            reminders: [],
            referenceDate: today,
            calendar: calendar
        )

        #expect(summary.tasksDueToday.map(\.title) == ["Hoje"])
        #expect(summary.pendingTasksCount == 2)
    }

    @Test func classifiesBillsAsDueTodayOrUpcoming() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let dueTodayBill = RecurringBill(title: "Aluguel", amount: 2000, recurrence: .monthly, nextDueDate: today, category: .housing)
        let upcomingDate = calendar.date(byAdding: .day, value: 3, to: today)!
        let upcomingBill = RecurringBill(title: "Academia", amount: 150, recurrence: .monthly, nextDueDate: upcomingDate, category: .health)
        let farDate = calendar.date(byAdding: .day, value: 30, to: today)!
        let farBill = RecurringBill(title: "Longe", amount: 50, recurrence: .monthly, nextDueDate: farDate, category: .other)

        let summary = TodaySummaryBuilder.build(
            tasks: [],
            recurringBills: [dueTodayBill, upcomingBill, farBill],
            installments: [],
            reminders: [],
            referenceDate: today,
            calendar: calendar
        )

        #expect(summary.billsDueToday.map(\.title) == ["Aluguel"])
        #expect(summary.totalDueTodayAmount == 2000)
        #expect(summary.upcoming.map(\.title) == ["Academia"])
    }
}
