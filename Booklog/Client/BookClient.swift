import SwiftData
import Foundation

struct BookClient: Sendable {
    func fetchBooks(for statusID: Status.ID, modelContext: ModelContext) throws -> [Book] {
        try modelContext.fetch(
            FetchDescriptor<Book>(
                predicate: #Predicate {
                    $0.status.id == statusID
                },
                sortBy: [
                    SortDescriptor(\.priority)
                ]
            )
        )
    }

    func fetchBook(id: Book.ID, modelContext: ModelContext) throws -> Book {
        guard let book = try modelContext.fetch(
            FetchDescriptor<Book>(
                predicate: #Predicate {
                    $0.id == id
                }
            )
        ).first else {
            throw Error.bookNotFound
        }
        return book
    }

    enum Error: LocalizedError {
        case bookNotFound

        var errorDescription: String? {
            switch self {
            case .bookNotFound:
                String(localized: "Book cannot be found")
            }
        }
    }
}
