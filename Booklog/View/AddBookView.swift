import SwiftUI

struct AddBookView: View {
    enum ViewType {
        case original
        case book(GoogleBooksClient.FormattedResponse)
    }

    enum FieldType: Equatable {
        case title, pageCount
    }

    @Environment(\.modelContext) private var modelContext
    @State private var book: Book
    @FocusState private var focusedField: FieldType?

    init(status: Status, viewType: ViewType) {
        let now = Date()
        switch viewType {
        case .original:
            self.book = Book(
                id: UUID(),
                tags: [],
                status: status,
                title: "",
                createdAt: now,
                updatedAt: now
            )
        case .book(let formattedResponse):
            self.book = Book(
                id: UUID(),
                tags: [],
                status: status,
                title: formattedResponse.title,
                authors: formattedResponse.authors,
                publisher: formattedResponse.publisher,
                publishedDate: formattedResponse.publishedDate,
                bookDescription: formattedResponse.description,
                smallThumbnail: formattedResponse.smallThumbnail,
                thumbnail: formattedResponse.thumbnail,
                expirationDate: nil,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    var body: some View {
        List {
            AsyncImage(url: book.thumbnailURL ?? BooklogConst.noImageThumbnailURL) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 211)
            } placeholder: {
                Rectangle().fill(.gray)
                    .frame(width: 150, height: 211)
            }
            .centered(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                print("hoge")
            }

            TextField("Title", text: $book.title, prompt: Text("Enter a book title"))
                .focused($focusedField, equals: .title)

            Section("Page Count") {
                TextField(
                    "Page Count",
                    value: .init(
                        get: {
                            if let readData = book.readData {
                                return readData.totalPage
                            } else {
                                return 0
                            }
                        },
                        set: {
                            if $0 <= 0 {
                                book.readData = nil
                            } else if book.readData != nil {
                                book.readData?.totalPage = $0
                            } else {
                                book.readData = Book.ReadData(totalPage: $0, currentPage: 0)
                            }
                        }
                    ),
                    format: .number,
                    prompt: Text("Enter a page count")
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .pageCount)
            }
        }
        .listStyle(.insetGrouped)
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {

                }
            }
        }
    }
}
