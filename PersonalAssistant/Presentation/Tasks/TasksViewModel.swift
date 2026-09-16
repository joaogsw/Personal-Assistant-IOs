import Foundation
import Observation

@MainActor
@Observable
final class TasksViewModel {
    private let repository: TaskRepository

    var tasks: [TaskItem] = []
    var errorMessage: String?

    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted { $0.priority > $1.priority }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func load() {
        do {
            tasks = try repository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar as tarefas."
        }
    }

    func addTask(title: String, notes: String?, dueDate: Date?, priority: TaskPriority) {
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority)
        do {
            try repository.insert(task)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível salvar a tarefa."
        }
    }

    func complete(_ task: TaskItem) {
        do {
            try repository.complete(task)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível concluir a tarefa."
        }
    }

    func delete(_ task: TaskItem) {
        do {
            try repository.delete(task)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível excluir a tarefa."
        }
    }
}
