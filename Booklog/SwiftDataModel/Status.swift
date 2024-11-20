import Foundation
import SwiftData

@Model
final class Status {
    #Unique<Status>([\.id], [\.parentBoard, \.priority], [\.title, \.parentBoard])

    @Relationship(deleteRule: .cascade, inverse: \Book.status)
    var books: [Book]
    var parentBoard: Board?
    var id: UUID
    var title: String
    var priority: Int
    var hexColorString: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        books: [Book],
        parentBoard: Board? = nil,
        title: String,
        priority: Int,
        hexColorString: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.books = books
        self.parentBoard = parentBoard
        self.title = title
        self.priority = priority
        self.hexColorString = hexColorString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct Entity: EntityConvertibleType {
        var books: [Book.Entity]
        var id: UUID
        var title: String
        var priority: Int
        var hexColorString: String
        var createdAt: Date
        var updatedAt: Date
    }

    static func createDefaultStatuses(now: Date = .now) -> [Status] {
        [
            .init(
                id: UUID(),
                books: [],
                title: String(localized: "Backlog"),
                priority: 0,
                hexColorString: "91918E",
                createdAt: now,
                updatedAt: now
            ),
            .init(
                id: UUID(),
                books: [],
                title: String(localized: "Todo"),
                priority: 1,
                hexColorString: "6B94B7",
                createdAt: now,
                updatedAt: now
            ),
            .init(
                id: UUID(),
                books: [],
                title: String(localized: "In progress"),
                priority: 2,
                hexColorString: "8460CC",
                createdAt: now,
                updatedAt: now
            ),
            .init(
                id: UUID(),
                books: [],
                title: String(localized: "Completed"),
                priority: 3,
                hexColorString: "769980",
                createdAt: now,
                updatedAt: now
            ),
        ]
    }
}

extension Status: EntityConvertible {
    func toEntity() -> Entity {
        Entity(
            books: books.map { $0.toEntity() },
            id: id,
            title: title,
            priority: priority,
            hexColorString: hexColorString,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
