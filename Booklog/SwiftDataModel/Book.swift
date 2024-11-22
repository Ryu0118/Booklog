import Foundation
import SwiftData

@Model
final class Book: Identifiable {
    #Unique<Book>([\.id], [\.title, \.status], [\.priority, \.status])
    @Attribute(.externalStorage) var thumbnailData: Data?

    @Relationship(inverse: \Tag.books) var tags: [Tag]
    @Relationship(deleteRule: .cascade, inverse: \Comment.parentBook) var comments: [Comment]

    var id: UUID
    var status: Status
    var title: String
    var priority: Int
    var readData: ReadData?
    var authors: [String]
    var publisher: String?
    var publishedDate: String?
    var bookDescription: String?
    var smallThumbnail: String?
    var thumbnail: String?

    var deadline: Date?
    var createdAt: Date
    var updatedAt: Date

    struct ReadData: Codable, Equatable, Hashable {
        var totalPage: Int
        var currentPage: Int

        var progress: Double {
            Double(currentPage) / Double(totalPage)
        }
    }

    init(
        id: UUID,
        thumbnailData: Data? = nil,
        tags: [Tag],
        comments: [Comment] = [],
        status: Status,
        readData: ReadData? = nil,
        title: String,
        priority: Int,
        authors: [String] = [],
        publisher: String? = nil,
        publishedDate: String? = nil,
        bookDescription: String? = nil,
        smallThumbnail: String? = nil,
        thumbnail: String? = nil,
        deadline: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.thumbnailData = thumbnailData
        self.tags = tags
        self.comments = comments
        self.status = status
        self.priority = priority
        self.readData = readData
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.bookDescription = bookDescription
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
        self.deadline = deadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    struct Entity: EntityConvertibleType {
        var id: UUID
        var thumbnailData: Data?
        var tags: [Tag.Entity] = []
        var comments: [Comment.Entity] = []
        var readData: ReadData?
        var title: String
        var priority: Int
        var authors: [String] = []
        var publisher: String?
        var publishedDate: String?
        var bookDescription: String?
        var smallThumbnail: String?
        var thumbnail: String?
        var deadline: Date?
        var createdAt: Date
        var updatedAt: Date

        var thumbnailURL: URL? {
            if let urlString = thumbnail ?? smallThumbnail {
                URL(string: urlString)
            } else {
                nil
            }
        }
    }
}

extension Book: EntityConvertible {
    func toEntity() -> Entity {
        Entity(
            id: id,
            thumbnailData: thumbnailData,
            tags: tags.map { $0.toEntity() },
            comments: comments.map { $0.toEntity() },
            readData: readData,
            title: title,
            priority: priority,
            authors: authors,
            publisher: publisher,
            publishedDate: publishedDate,
            bookDescription: bookDescription,
            smallThumbnail: smallThumbnail,
            thumbnail: thumbnail,
            deadline: deadline,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Book.Entity {
    func toOriginalModel(status: Status, tags: [Tag], comments: [Comment]) -> Book {
        Book(
            id: id,
            thumbnailData: thumbnailData,
            tags: tags,
            comments: comments,
            status: status,
            readData: readData,
            title: title,
            priority: priority,
            authors: authors,
            publisher: publisher,
            publishedDate: publishedDate,
            bookDescription: bookDescription,
            smallThumbnail: smallThumbnail,
            thumbnail: thumbnail,
            deadline: deadline,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
