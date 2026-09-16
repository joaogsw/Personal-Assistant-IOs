import Foundation

/// Abstracts persistence for `ShoppingList` and its child `ShoppingListItem` entries.
protocol ShoppingListRepository {
    func fetchAllLists() throws -> [ShoppingList]
    func insert(_ list: ShoppingList) throws
    func delete(_ list: ShoppingList) throws

    func addItem(_ item: ShoppingListItem, to list: ShoppingList) throws
    func deleteItem(_ item: ShoppingListItem) throws
    func deleteCompletedItems(in list: ShoppingList) throws

    func save() throws
}
