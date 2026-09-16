import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var category: ExpenseCategory = .other
    @State private var paymentMethod: PaymentMethod = .creditCard
    @State private var notes = ""

    let onSave: (String, Decimal, Date, ExpenseCategory, PaymentMethod, String?) -> Void

    private var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    TextField("Título", text: $title)
                    TextField("Valor", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }

                Section("Categoria e pagamento") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    Picker("Forma de pagamento", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }

                Section("Notas") {
                    TextField("Observações (opcional)", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Nova Despesa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        guard let amount = parsedAmount else { return }
                        onSave(title, amount, date, category, paymentMethod, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
