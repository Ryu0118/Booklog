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

    struct CodableComment: Codable {
        var id: UUID
        var parentBook: Book.CodableBook
        var text: String
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Comment: SwiftDataTransferable {
    func toCodableModel() -> CodableComment {
        CodableComment(
            id: id,
            parentBook: parentBook.toCodableModel(),
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func toOriginalModel(from codableComment: CodableComment) -> Comment {
        Comment(
            id: codableComment.id,
            parentBook: Book.toOriginalModel(from: codableComment.parentBook),
            text: codableComment.text,
            createdAt: codableComment.createdAt,
            updatedAt: codableComment.updatedAt
        )
    }
}
