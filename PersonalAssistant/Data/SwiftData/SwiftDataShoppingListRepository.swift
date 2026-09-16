import Foundation
import SwiftData

final class SwiftDataShoppingListRepository: ShoppingListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAllLists() throws -> [ShoppingList] {
        let descriptor = FetchDescriptor<ShoppingList>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ list: ShoppingList) throws {
        context.insert(list)
    }

    func delete(_ list: ShoppingList) throws {
        context.delete(list)
    }

    func addItem(_ item: ShoppingListItem, to list: ShoppingList) throws {
        item.list = list
        list.items.append(item)
        context.insert(item)
    }

    func deleteItem(_ item: ShoppingListItem) throws {
        context.delete(item)
    }

    func deleteCompletedItems(in list: ShoppingList) throws {
        for item in list.items where item.isCompleted {
            context.delete(item)
        }
    }

    func save() throws {
        try context.save()
    }
}
