import Foundation
import SwiftData

@Model
final class Board {
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

    struct CodableBoard: Codable {
        var status: [Status.CodableStatus]
        var id: UUID
        var name: String
        var priority: Int
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Board: SwiftDataTransferable {
    func toCodableModel() -> CodableBoard {
        CodableBoard(status: status.map { $0.toCodableModel() }, id: id, name: name, priority: priority, createdAt: createdAt, updatedAt: updatedAt)
    }

    static func toOriginalModel(from codableBoard: CodableBoard) -> Board {
        Board(
            status: codableBoard.status.map { Status.toOriginalModel(from: $0) },
            id: codableBoard.id,
            name: codableBoard.name,
            priority: codableBoard.priority,
            createdAt: codableBoard.createdAt,
            updatedAt: codableBoard.updatedAt
        )
    }
}
