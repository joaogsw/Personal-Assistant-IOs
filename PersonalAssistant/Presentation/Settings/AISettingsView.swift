import SwiftUI

struct AISettingsView: View {
    @State var viewModel: AISettingsViewModel

    var body: some View {
        Form {
            Section("Provedor") {
                LabeledContent("Provider", value: viewModel.configuration.provider.displayName)
                LabeledContent("Modelo", value: viewModel.configuration.model)
            }

            Section("Chave de API") {
                if viewModel.hasStoredKey {
                    Label("Chave configurada", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Nenhuma chave configurada", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                }

                SecureField("Cole sua Anthropic API Key", text: $viewModel.apiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                Button("Salvar chave") { viewModel.saveAPIKey() }
                    .disabled(viewModel.apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Remover chave", role: .destructive) { viewModel.removeAPIKey() }
                    .disabled(!viewModel.hasStoredKey)
            }

            Section("Testar conexão") {
                Button {
                    Task { await viewModel.testConnection() }
                } label: {
                    if viewModel.connectionTestState == .testing {
                        ProgressView()
                    } else {
                        Text("Testar conexão")
                    }
                }
                .disabled(!viewModel.hasStoredKey || viewModel.connectionTestState == .testing)

                switch viewModel.connectionTestState {
                case .success(let message):
                    Label(message, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                case .failure(let message):
                    Label(message, systemImage: "xmark.circle.fill").foregroundStyle(.red)
                case .idle, .testing:
                    EmptyView()
                }
            }

            if let statusMessage = viewModel.statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Sua chave fica armazenada apenas no Keychain deste dispositivo. Ela nunca é incluída no código-fonte, no repositório, ou em nenhum arquivo do app, e só é enviada para a API da Anthropic.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Inteligência Artificial")
    }
}
