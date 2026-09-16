import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private let taskRepository: TaskRepository
    private let recurringBillRepository: RecurringBillRepository
    private let installmentRepository: InstallmentRepository
    private let reminderRepository: ReminderRepository
    private let dateProvider: DateProviding

    var summary = TodaySummary(
        tasksDueToday: [],
        billsDueToday: [],
        upcoming: [],
        remindersToday: [],
        pendingTasksCount: 0,
        totalDueTodayAmount: 0
    )
    var errorMessage: String?

    init(
        taskRepository: TaskRepository,
        recurringBillRepository: RecurringBillRepository,
        installmentRepository: InstallmentRepository,
        reminderRepository: ReminderRepository,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.taskRepository = taskRepository
        self.recurringBillRepository = recurringBillRepository
        self.installmentRepository = installmentRepository
        self.reminderRepository = reminderRepository
        self.dateProvider = dateProvider
    }

    func load() {
        do {
            let tasks = try taskRepository.fetchAll()
            let bills = try recurringBillRepository.fetchAll()
            let installments = try installmentRepository.fetchAllInstallments()
            let reminders = try reminderRepository.fetchAll()
            summary = TodaySummaryBuilder.build(
                tasks: tasks,
                recurringBills: bills,
                installments: installments,
                reminders: reminders,
                referenceDate: dateProvider.now()
            )
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar os dados de hoje."
        }
    }
}
