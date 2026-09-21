import SwiftUI

struct AssistantView: View {
    @State var viewModel: AssistantViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if viewModel.messages.isEmpty && viewModel.pendingActions.isEmpty {
                                EmptyStateView(
                                    systemImage: "bubble.left.and.bubble.right",
                                    title: "Fale com o assistente",
                                    message: "Experimente: \"Adiciona leite na lista Mercado\" ou \"Tenho que ligar para o Felipe amanhã às 14h\"."
                                )
                                .padding(.top, 40)
                            }

                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            ForEach(viewModel.pendingActions) { pending in
                                PendingActionCard(
                                    pendingAction: pending,
                                    onConfirm: { Task { await viewModel.confirm(pending) } },
                                    onCancel: { viewModel.cancel(pending) }
                                )
                            }

                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) {
                        if let lastID = viewModel.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack(alignment: .bottom) {
                    TextField("Digite uma mensagem...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        Task { await viewModel.send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Assistente")
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

private struct PendingActionCard: View {
    let pendingAction: PendingAction
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirmar lançamento")
                .font(.headline)
            Text(pendingAction.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Button("Cancelar", role: .cancel, action: onCancel)
                Spacer()
                Button("Confirmar", action: onConfirm)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
