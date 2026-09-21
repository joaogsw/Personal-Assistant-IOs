import SwiftUI

struct SettingsView: View {
    let keychainService: KeychainServicing
    let aiConfigurationStore: AIConfigurationStoring

    var body: some View {
        NavigationStack {
            List {
                Section("Privacidade") {
                    Label("Todos os dados ficam neste dispositivo", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                }

                Section("Inteligência Artificial") {
                    NavigationLink("Configurar assistente") {
                        AISettingsView(
                            viewModel: AISettingsViewModel(
                                keychainService: keychainService,
                                configurationStore: aiConfigurationStore
                            )
                        )
                    }
                }

                Section("Sobre") {
                    LabeledContent("Versão", value: "1.0 (Etapa 2)")
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
