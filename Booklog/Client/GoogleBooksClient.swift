import Foundation

struct GoogleBooksClient: Sendable {
    private let session = URLSession.shared
    private let jsonDecoder = JSONDecoder()

    func getBooks(keyword: String) async throws -> [FormattedResponse] {
        var url = URL(string: "https://www.googleapis.com/books/v1/volumes")!
        url.append(queryItems: [
            URLQueryItem(
                name: "q",
                value: keyword
            )
        ])
        let (data, _) = try await session.data(from: url)
        let rawResponse = try jsonDecoder.decode(RawResponse.self, from: data)
        let books = rawResponse.items.map { $0.format() }

        guard !books.isEmpty else {
            throw Error.notFound
        }

        return books
    }

    func getBook(isbn: String) async throws -> FormattedResponse {
        var url = URL(string: "https://www.googleapis.com/books/v1/volumes")!
        url.append(queryItems: [
            URLQueryItem(
                name: "q",
                value: "isbn:" + isbn
            )
        ])
        let (data, _) = try await session.data(from: url)
        let rawResponse = try jsonDecoder.decode(RawResponse.self, from: data)

        guard let book = rawResponse.items.map({ $0.format() }).first else {
            throw Error.notFound
        }

        return book
    }

    enum Error: LocalizedError {
        case notFound

        var errorDescription: String? {
            switch self {
            case .notFound:
                String(localized: "No books were found")
            }
        }
    }

    struct RawResponse: Decodable, Sendable {
        let items: [Item]

        struct Item: Codable, Sendable {
            let volumeInfo: VolumeInfo

            struct VolumeInfo: Codable, Sendable {
                let title: String
                let authors: [String]?
                let publisher: String?
                let publishedDate: String?
                let description: String?
                let imageLinks: ImageLinks?

                struct ImageLinks: Codable, Sendable {
                    let smallThumbnail: String?
                    let thumbnail: String?
                }
            }
        }
    }

    struct FormattedResponse: Decodable, Identifiable, Hashable {
        var id: String { title }

        let title: String
        let authors: [String]
        let publisher: String?
        let publishedDate: String?
        let description: String?
        let smallThumbnail: String?
        let thumbnail: String?
    }
}

extension GoogleBooksClient.RawResponse.Item {
    func format() -> GoogleBooksClient.FormattedResponse {
        GoogleBooksClient.FormattedResponse(
            title: volumeInfo.title,
            authors: volumeInfo.authors ?? [],
            publisher: volumeInfo.publisher,
            publishedDate: volumeInfo.publishedDate,
            description: volumeInfo.description,
            smallThumbnail: volumeInfo.imageLinks?.smallThumbnail,
            thumbnail: volumeInfo.imageLinks?.thumbnail
        )
    }
}
