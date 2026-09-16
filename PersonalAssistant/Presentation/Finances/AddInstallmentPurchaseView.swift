import SwiftUI

struct AddInstallmentPurchaseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var totalAmountText = ""
    @State private var installmentCount = 2
    @State private var firstInstallmentDate = Date.now
    @State private var paymentMethod: PaymentMethod = .creditCard

    let onSave: (String, Decimal, Int, Date, PaymentMethod) -> Void

    private var parsedTotalAmount: Decimal? {
        Decimal(string: totalAmountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (parsedTotalAmount ?? 0) > 0 && installmentCount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Compra") {
                    TextField("Título", text: $title)
                    TextField("Valor total", text: $totalAmountText)
                        .keyboardType(.decimalPad)
                    Stepper("Parcelas: \(installmentCount)", value: $installmentCount, in: 2...48)
                    DatePicker("Primeira parcela", selection: $firstInstallmentDate, displayedComponents: .date)
                    Picker("Forma de pagamento", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }

                if let amount = parsedTotalAmount, installmentCount > 0 {
                    Section("Prévia") {
                        Text("\(installmentCount)x de aproximadamente \((amount / Decimal(installmentCount)).currencyFormatted)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Compra Parcelada")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        guard let amount = parsedTotalAmount else { return }
                        onSave(title, amount, installmentCount, firstInstallmentDate, paymentMethod)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
