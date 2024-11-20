import Foundation
import SwiftData

@Model
final class Tag {
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

    struct CodableTag: Codable {
        var id: UUID
        var name: String
        var books: [Book.CodableBook]
        var hexColorString: String
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Tag: SwiftDataTransferable {
    func toCodableModel() -> CodableTag {
        CodableTag(
            id: id,
            name: name,
            books: books.map { $0.toCodableModel() },
            hexColorString: hexColorString,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func toOriginalModel(from codableModel: CodableTag) -> Tag {
        Tag(
            id: codableModel.id,
            books: codableModel.books.map { Book.toOriginalModel(from: $0) },
            name: codableModel.name,
            hexColorString: codableModel.hexColorString,
            createdAt: codableModel.createdAt,
            updatedAt: codableModel.updatedAt
        )
    }
}
