import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    @Relationship(inverse: \Tag.books) var tags: [Tag]
    @Relationship(deleteRule: .cascade, inverse: \Comment.parentBook) var comments: [Comment]

    var status: Status
    var title: String
    var authors: [String]
    var publisher: String?
    var publishedDate: String?
    var bookDescription: String?
    var smallThumbnail: String?
    var thumbnail: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        tags: [Tag],
        comments: [Comment],
        status: Status,
        title: String,
        authors: [String],
        publisher: String? = nil,
        publishedDate: String? = nil,
        bookDescription: String? = nil,
        smallThumbnail: String? = nil,
        thumbnail: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.tags = tags
        self.comments = comments
        self.status = status
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.bookDescription = bookDescription
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
