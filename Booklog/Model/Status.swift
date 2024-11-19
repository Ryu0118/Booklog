import Foundation
import SwiftData

@Model
final class Status {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var priority: Int
    @Relationship(deleteRule: .cascade, inverse: \Book.status)
    var books: [Book]
    var board: Board

    var title: String
    var hexColorString: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        priority: Int,
        board: Board,
        books: [Book],
        title: String,
        hexColorString: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.priority = priority
        self.board = board
        self.books = books
        self.title = title
        self.hexColorString = hexColorString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
