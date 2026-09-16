import Foundation
import Observation

@MainActor
@Observable
final class ShoppingListsViewModel {
    private let repository: ShoppingListRepository

    var lists: [ShoppingList] = []
    var errorMessage: String?

    init(repository: ShoppingListRepository) {
        self.repository = repository
    }

    func load() {
        do {
            lists = try repository.fetchAllLists()
            errorMessage = nil
        } catch {
            errorMessage = "Não foi possível carregar as listas."
        }
    }

    func addList(title: String) {
        let list = ShoppingList(title: title)
        do {
            try repository.insert(list)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível criar a lista."
        }
    }

    func delete(_ list: ShoppingList) {
        do {
            try repository.delete(list)
            try repository.save()
            load()
        } catch {
            errorMessage = "Não foi possível excluir a lista."
        }
    }

    func addItem(name: String, quantity: Int?, to list: ShoppingList) {
        let item = ShoppingListItem(name: name, quantity: quantity, list: list)
        do {
            try repository.addItem(item, to: list)
            try repository.save()
        } catch {
            errorMessage = "Não foi possível adicionar o item."
        }
    }

    func toggleCompletion(_ item: ShoppingListItem) {
        item.isCompleted.toggle()
        do {
            try repository.save()
        } catch {
            errorMessage = "Não foi possível atualizar o item."
        }
    }

    func deleteItem(_ item: ShoppingListItem) {
        do {
            try repository.deleteItem(item)
            try repository.save()
        } catch {
            errorMessage = "Não foi possível excluir o item."
        }
    }

    func deleteCompletedItems(in list: ShoppingList) {
        do {
            try repository.deleteCompletedItems(in: list)
            try repository.save()
        } catch {
            errorMessage = "Não foi possível limpar os itens concluídos."
        }
    }
}
