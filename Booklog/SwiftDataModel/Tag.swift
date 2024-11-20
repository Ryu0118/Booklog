import Foundation
import SwiftData

@Model
final class Tag: Identifiable {
    #Unique<Tag>([\.id], [\.name])

    var id: UUID
    var name: String
    var books: [Book]
    var hexColorString: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, books: [Book], name: String, hexColorString: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.books = books
        self.name = name
        self.hexColorString = hexColorString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct Entity: EntityConvertibleType {
        var id: UUID
        var name: String
        var books: [Book.Entity] = []
        var hexColorString: String
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Tag: EntityConvertible {
    func toEntity() -> Entity {
        Entity(
            id: id,
            name: name,
            books: books.map { $0.toEntity() },
            hexColorString: hexColorString,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
