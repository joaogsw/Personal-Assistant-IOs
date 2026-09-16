import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date.now
    @State private var priority: TaskPriority = .medium

    let onSave: (String, String?, Date?, TaskPriority) -> Void

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarefa") {
                    TextField("Título", text: $title)
                    TextField("Notas (opcional)", text: $notes, axis: .vertical)
                    Picker("Prioridade", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }

                Section("Vencimento") {
                    Toggle("Definir data de vencimento", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Vencimento", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Nova Tarefa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        onSave(title, notes.isEmpty ? nil : notes, hasDueDate ? dueDate : nil, priority)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
