import SwiftData
import Foundation

enum BooklogConst {
    static let modelTypes: [any PersistentModel.Type] = [
        Book.self,
        Comment.self,
        Status.self,
        Tag.self,
        Board.self
    ]

    static func schema() -> Schema {
        Schema(modelTypes)
    }

    static let noImageThumbnailURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg")!
}
