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
}
