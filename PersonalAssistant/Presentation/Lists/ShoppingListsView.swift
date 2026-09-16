import SwiftUI

struct ShoppingListsView: View {
    @State var viewModel: ShoppingListsViewModel
    @State private var isPresentingAddList = false
    @State private var newListTitle = ""

    var body: some View {
        NavigationStack {
            List {
                if viewModel.lists.isEmpty {
                    EmptyStateView(
                        systemImage: "cart",
                        title: "Nenhuma lista",
                        message: "Crie sua primeira lista, como Mercado ou Farmácia."
                    )
                } else {
                    ForEach(viewModel.lists) { list in
                        NavigationLink {
                            ShoppingListDetailView(list: list, viewModel: viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.title)
                                Text("\(list.items.filter { !$0.isCompleted }.count) itens pendentes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.delete(viewModel.lists[index])
                        }
                    }
                }
            }
            .navigationTitle("Listas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Nova Lista", isPresented: $isPresentingAddList) {
                TextField("Nome da lista", text: $newListTitle)
                Button("Cancelar", role: .cancel) { newListTitle = "" }
                Button("Criar") {
                    let title = newListTitle.trimmingCharacters(in: .whitespaces)
                    if !title.isEmpty {
                        viewModel.addList(title: title)
                    }
                    newListTitle = ""
                }
            }
            .task { viewModel.load() }
        }
    }
}
