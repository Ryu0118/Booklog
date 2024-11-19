import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID

    var books: [Book]

    var name: String
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
}
