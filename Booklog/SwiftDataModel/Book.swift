import Foundation
import SwiftData

@Model
final class Book {
    #Unique<Book>([\.id], [\.title, \.status])

    @Relationship(inverse: \Tag.books) var tags: [Tag]
    @Relationship(deleteRule: .cascade, inverse: \Comment.parentBook) var comments: [Comment]

    var id: UUID
    var status: Status
    var title: String
    var readData: ReadData?
    var authors: [String]
    var publisher: String?
    var publishedDate: String?
    var bookDescription: String?
    var smallThumbnail: String?
    var thumbnail: String?

    var expirationDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var thumbnailURL: URL? {
        if let urlString = thumbnail ?? smallThumbnail {
            URL(string: urlString)
        } else {
            nil
        }
    }

    struct ReadData: Codable {
        var totalPage: Int
        var currentPage: Int

        var progress: Double {
            Double(currentPage) / Double(totalPage)
        }
    }

    init(
        id: UUID,
        tags: [Tag],
        comments: [Comment] = [],
        status: Status,
        readData: ReadData? = nil,
        title: String,
        authors: [String] = [],
        publisher: String? = nil,
        publishedDate: String? = nil,
        bookDescription: String? = nil,
        smallThumbnail: String? = nil,
        thumbnail: String? = nil,
        expirationDate: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.tags = tags
        self.comments = comments
        self.status = status
        self.readData = readData
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.bookDescription = bookDescription
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
        self.expirationDate = expirationDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct CodableBook: Codable {
        var id: UUID
        var tags: [Tag.CodableTag]
        var comments: [Comment.CodableComment]
        var status: Status.CodableStatus
        var readData: ReadData?
        var title: String
        var authors: [String]
        var publisher: String?
        var publishedDate: String?
        var bookDescription: String?
        var smallThumbnail: String?
        var thumbnail: String?
        var expirationDate: Date?
        var createdAt: Date
        var updatedAt: Date
    }
}

extension Book: SwiftDataTransferable {
    func toCodableModel() -> CodableBook {
        CodableBook(
            id: id,
            tags: tags.map { $0.toCodableModel() },
            comments: comments.map { $0.toCodableModel() },
            status: status.toCodableModel(),
            readData: readData,
            title: title,
            authors: authors,
            publisher: publisher,
            publishedDate: publishedDate,
            bookDescription: bookDescription,
            smallThumbnail: smallThumbnail,
            thumbnail: thumbnail,
            expirationDate: expirationDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func toOriginalModel(from codableBook: CodableBook) -> Book {
        Book(
            id: codableBook.id,
            tags: codableBook.tags.map { Tag.toOriginalModel(from: $0) },
            comments: codableBook.comments.map { Comment.toOriginalModel(from: $0) },
            status: Status.toOriginalModel(from: codableBook.status),
            readData: codableBook.readData,
            title: codableBook.title,
            authors: codableBook.authors,
            publisher: codableBook.publisher,
            publishedDate: codableBook.publishedDate,
            bookDescription: codableBook.bookDescription,
            smallThumbnail: codableBook.smallThumbnail,
            thumbnail: codableBook.thumbnail,
            expirationDate: codableBook.expirationDate,
            createdAt: codableBook.createdAt,
            updatedAt: codableBook.updatedAt
        )
    }
}
