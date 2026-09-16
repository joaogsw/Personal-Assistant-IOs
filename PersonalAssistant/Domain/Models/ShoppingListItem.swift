import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var id: UUID
    var name: String
    /// Simple optional unit count (e.g. 2 units). Not a free-form string, to keep entry fast and structured.
    var quantity: Int?
    var isCompleted: Bool
    var createdAt: Date
    var list: ShoppingList?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        list: ShoppingList? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.list = list
    }
}
