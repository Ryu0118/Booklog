import Foundation
import SwiftData

@Model
final class Board: Identifiable {
    #Unique<Board>([\.id], [\.name], [\.priority])
    @Relationship(deleteRule: .cascade, inverse: \Status.parentBoard) var status: [Status]

    var id: UUID
    var name: String
    var priority: Int
    var createdAt: Date
    var updatedAt: Date

    init(status: [Status], id: UUID, name: String, priority: Int, createdAt: Date, updatedAt: Date) {
        self.status = status
        self.id = id
        self.name = name
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct Entity: EntityConvertibleType {
        var status: [Status.Entity]
        var id: UUID
        var name: String
        var priority: Int
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Board: EntityConvertible {
    func toEntity() -> Entity {
        Entity(status: status.map { $0.toEntity() }, id: id, name: name, priority: priority, createdAt: createdAt, updatedAt: updatedAt)
    }
}
