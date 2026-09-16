import SwiftUI

struct TasksView: View {
    @State var viewModel: TasksViewModel
    @State private var isPresentingAddTask = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pendentes") {
                    if viewModel.pendingTasks.isEmpty {
                        Text("Nenhuma tarefa pendente.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.pendingTasks) { task in
                            TaskRow(task: task)
                                .swipeActions {
                                    Button("Concluir") { viewModel.complete(task) }
                                        .tint(.green)
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.pendingTasks[index])
                            }
                        }
                    }
                }

                if !viewModel.completedTasks.isEmpty {
                    Section("Concluídas") {
                        ForEach(viewModel.completedTasks) { task in
                            TaskRow(task: task)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.completedTasks[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tarefas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTask) {
                AddTaskView { title, notes, dueDate, priority in
                    viewModel.addTask(title: title, notes: notes, dueDate: dueDate, priority: priority)
                }
            }
            .task { viewModel.load() }
        }
    }
}

private struct TaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(task.priority.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
