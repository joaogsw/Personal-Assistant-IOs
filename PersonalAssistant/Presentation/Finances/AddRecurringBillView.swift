import SwiftUI

struct AddRecurringBillView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amountText = ""
    @State private var recurrence: RecurrenceFrequency = .monthly
    @State private var nextDueDate = Date.now
    @State private var reminderDaysBefore = 0
    @State private var category: ExpenseCategory = .other

    let onSave: (String, Decimal, RecurrenceFrequency, Date, Int, ExpenseCategory) -> Void

    private var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Conta") {
                    TextField("Título", text: $title)
                    TextField("Valor", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Recorrência", selection: $recurrence) {
                        ForEach(RecurrenceFrequency.allCases) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    DatePicker("Próximo vencimento", selection: $nextDueDate, displayedComponents: .date)
                    Stepper("Lembrar \(reminderDaysBefore) dia(s) antes", value: $reminderDaysBefore, in: 0...30)
                    Picker("Categoria", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Conta Recorrente")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        guard let amount = parsedAmount else { return }
                        onSave(title, amount, recurrence, nextDueDate, reminderDaysBefore, category)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
