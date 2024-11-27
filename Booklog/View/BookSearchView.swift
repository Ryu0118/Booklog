import SwiftUI

struct BookSearchView: View {
    enum Const {
        static let thumbnailWidth: CGFloat = 55
        static let thumbnailHeight: CGFloat = 78
    }

    @State private var searchQuery: String = ""
    @State private var addingBook: GoogleBooksClient.FormattedResponse?
    @State private var books: [GoogleBooksClient.FormattedResponse] = []
    @State private var task: Task<Void, any Error>?
    @State private var isAlertPresented = false
    @State private var presentingError: (any LocalizedError)?

    private let booksClient = GoogleBooksClient()

    let status: Status

    var body: some View {
        NavigationStack {
            List(books) { book in
                Button {
                    addingBook = book
                } label: {
                    HStack {
                        AsyncImage(url: URL(string: book.thumbnail ?? book.smallThumbnail ?? "")) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                        } placeholder: {
                            Rectangle().fill(Color.gray)
                                .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                        }
                        Text(book.title)
                            .lineLimit(3)
                            .font(.body)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Search books")
            .searchable(text: $searchQuery, isPresented: .constant(true), prompt: "Enter the name of the book you want to search")
            .onSubmit(of: .search) {
                task = Task {
                    do {
                        books = try await booksClient.getBooks(keyword: searchQuery)
                    } catch {
                        showError(error: BooklogError.requestError)
                    }
                }
            }
            .navigationDestination(item: $addingBook) { book in
                AddBookView(status: status, viewType: .new(.book(book)))
            }
            .alert("An error has occurred", isPresented: $isAlertPresented, presenting: presentingError) { error in
                Button("OK", role: .cancel) {
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onDisappear {
                task?.cancel()
            }
        }
    }

    private func showError(error: any LocalizedError) {
        isAlertPresented = true
        presentingError = error
    }
}
