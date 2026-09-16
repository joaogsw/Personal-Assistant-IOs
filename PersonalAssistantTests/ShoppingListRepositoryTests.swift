import Foundation
import Testing
@testable import PersonalAssistant

struct ShoppingListRepositoryTests {
    @Test func creatingListAndAddingItemPersistsThem() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataShoppingListRepository(context: context)

        let list = ShoppingList(title: "Mercado")
        try repository.insert(list)
        try repository.save()

        let item = ShoppingListItem(name: "Leite", quantity: 2)
        try repository.addItem(item, to: list)
        try repository.save()

        let lists = try repository.fetchAllLists()
        #expect(lists.count == 1)
        #expect(lists.first?.items.count == 1)
        #expect(lists.first?.items.first?.name == "Leite")
    }

    @Test func completingItemMarksItAsCompleted() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataShoppingListRepository(context: context)

        let list = ShoppingList(title: "Farmácia")
        try repository.insert(list)
        let item = ShoppingListItem(name: "Dipirona")
        try repository.addItem(item, to: list)
        try repository.save()

        item.isCompleted = true
        try repository.save()

        #expect(item.isCompleted)
    }

    @Test func deletingCompletedItemsRemovesOnlyThose() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataShoppingListRepository(context: context)

        let list = ShoppingList(title: "Mercado")
        try repository.insert(list)
        let pending = ShoppingListItem(name: "Café")
        let completed = ShoppingListItem(name: "Ovos", isCompleted: true)
        try repository.addItem(pending, to: list)
        try repository.addItem(completed, to: list)
        try repository.save()

        try repository.deleteCompletedItems(in: list)
        try repository.save()

        #expect(list.items.map(\.name) == ["Café"])
    }
}
