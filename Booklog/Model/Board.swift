import Foundation
import SwiftData

@Model
final class Board {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade, inverse: \Status.board) var status: [Status]

    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, status: [Status], name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.status = status
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
