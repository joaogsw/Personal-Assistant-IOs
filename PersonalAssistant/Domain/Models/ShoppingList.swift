import Foundation
import SwiftData

@Model
final class ShoppingList {
    var id: UUID
    var title: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ShoppingListItem.list)
    var items: [ShoppingListItem] = []

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}
