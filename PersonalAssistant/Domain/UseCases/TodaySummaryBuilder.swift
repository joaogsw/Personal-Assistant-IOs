import Foundation

/// A due item that unifies `RecurringBill` and `Installment` for display purposes,
/// without merging their persistence models.
struct DueItem: Identifiable {
    enum Kind {
        case recurringBill(RecurringBill)
        case installment(Installment)
    }

    let id: UUID
    let title: String
    let amount: Decimal
    let dueDate: Date
    let kind: Kind
}

struct TodaySummary {
    let tasksDueToday: [TaskItem]
    let billsDueToday: [DueItem]
    let upcoming: [DueItem]
    let remindersToday: [Reminder]
    let pendingTasksCount: Int
    let totalDueTodayAmount: Decimal
}

/// Aggregates already-fetched entities into the data the "Hoje" screen needs.
/// Pure logic operating on in-memory arrays — no persistence, no SwiftData dependency.
enum TodaySummaryBuilder {
    static func build(
        tasks: [TaskItem],
        recurringBills: [RecurringBill],
        installments: [Installment],
        reminders: [Reminder],
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        upcomingWindowDays: Int = 7
    ) -> TodaySummary {
        let today = calendar.startOfDay(for: referenceDate)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let windowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: today) else {
            return TodaySummary(
                tasksDueToday: [],
                billsDueToday: [],
                upcoming: [],
                remindersToday: [],
                pendingTasksCount: tasks.filter { !$0.isCompleted }.count,
                totalDueTodayAmount: 0
            )
        }

        let tasksDueToday = tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let due = task.dueDate else { return false }
                return due >= today && due < tomorrow
            }
            .sorted { $0.priority > $1.priority }

        let pendingTasksCount = tasks.filter { !$0.isCompleted }.count

        let activeBills = recurringBills.filter { $0.isActive }
        let unpaidInstallments = installments.filter { !$0.isPaid }

        let billItemsToday = activeBills
            .filter { $0.nextDueDate >= today && $0.nextDueDate < tomorrow }
            .map { DueItem(id: $0.id, title: $0.title, amount: $0.amount, dueDate: $0.nextDueDate, kind: .recurringBill($0)) }

        let installmentItemsToday = unpaidInstallments
            .filter { $0.dueDate >= today && $0.dueDate < tomorrow }
            .map { DueItem(id: $0.id, title: $0.plan?.title ?? "Parcela", amount: $0.amount, dueDate: $0.dueDate, kind: .installment($0)) }

        let billsDueToday = (billItemsToday + installmentItemsToday).sorted { $0.title < $1.title }

        let upcomingBills = activeBills
            .filter { $0.nextDueDate >= tomorrow && $0.nextDueDate < windowEnd }
            .map { DueItem(id: $0.id, title: $0.title, amount: $0.amount, dueDate: $0.nextDueDate, kind: .recurringBill($0)) }

        let upcomingInstallments = unpaidInstallments
            .filter { $0.dueDate >= tomorrow && $0.dueDate < windowEnd }
            .map { DueItem(id: $0.id, title: $0.plan?.title ?? "Parcela", amount: $0.amount, dueDate: $0.dueDate, kind: .installment($0)) }

        let upcoming = (upcomingBills + upcomingInstallments).sorted { $0.dueDate < $1.dueDate }

        let remindersToday = reminders
            .filter { !$0.isCompleted }
            .filter { $0.reminderDate >= today && $0.reminderDate < tomorrow }
            .sorted { $0.reminderDate < $1.reminderDate }

        let totalDueTodayAmount = billsDueToday.reduce(Decimal(0)) { $0 + $1.amount }

        return TodaySummary(
            tasksDueToday: tasksDueToday,
            billsDueToday: billsDueToday,
            upcoming: upcoming,
            remindersToday: remindersToday,
            pendingTasksCount: pendingTasksCount,
            totalDueTodayAmount: totalDueTodayAmount
        )
    }
}
