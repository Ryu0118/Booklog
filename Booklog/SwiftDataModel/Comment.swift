import Foundation
import SwiftData

@Model
final class Comment {
    @Attribute(.unique) var id: UUID
    var parentBook: Book
    var text: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, parentBook: Book, text: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.parentBook = parentBook
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct Entity: EntityConvertibleType {
        var id: UUID
        var text: String
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Comment: EntityConvertible {
    func toEntity() -> Entity {
        Entity(
            id: id,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
