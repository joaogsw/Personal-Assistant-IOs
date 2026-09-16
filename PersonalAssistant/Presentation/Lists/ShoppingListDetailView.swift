import SwiftUI

struct ShoppingListDetailView: View {
    let list: ShoppingList
    var viewModel: ShoppingListsViewModel
    @State private var newItemName = ""

    private var pendingItems: [ShoppingListItem] {
        list.items.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
    }

    private var completedItems: [ShoppingListItem] {
        list.items.filter(\.isCompleted).sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Adicionar item", text: $newItemName)
                    Button("Adicionar") {
                        let name = newItemName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        viewModel.addItem(name: name, quantity: nil, to: list)
                        newItemName = ""
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if !pendingItems.isEmpty {
                Section("Pendentes") {
                    ForEach(pendingItems) { item in
                        itemRow(item)
                    }
                }
            }

            if !completedItems.isEmpty {
                Section("Concluídos") {
                    ForEach(completedItems) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .navigationTitle(list.title)
        .toolbar {
            if !completedItems.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Limpar concluídos") {
                        viewModel.deleteCompletedItems(in: list)
                    }
                }
            }
        }
    }

    private func itemRow(_ item: ShoppingListItem) -> some View {
        HStack {
            Button {
                viewModel.toggleCompletion(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.name)
                .strikethrough(item.isCompleted)

            if let quantity = item.quantity {
                Spacer()
                Text("x\(quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions {
            Button("Excluir", role: .destructive) {
                viewModel.deleteItem(item)
            }
        }
    }
}
