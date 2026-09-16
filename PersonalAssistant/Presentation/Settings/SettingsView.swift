import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Privacidade") {
                    Label("Todos os dados ficam neste dispositivo", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                }
                Section("Assistente (em breve)") {
                    Label("Comandos por voz e IA chegarão em uma etapa futura", systemImage: "sparkles")
                        .foregroundStyle(.secondary)
                }
                Section("Sobre") {
                    LabeledContent("Versão", value: "1.0 (Etapa 1)")
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
