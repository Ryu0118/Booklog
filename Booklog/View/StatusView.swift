import SwiftUI
import SwiftData

struct StatusView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.mainWindowSize) private var mainWindowSize
    @Environment(\.modelContext) private var modelContext

    @State private var isBarcodeScannerPresented = false
    @State private var recognizedIsbn: String?
    @State private var isErrorAlertPresented = false
    @State private var localizedError: (any LocalizedError)?
    @State private var scannedBook: GoogleBooksClient.FormattedResponse?
    @State private var isAddBookViewPresented = false

    let status: Status
    @State var books: [Book.Entity] = []

    var body: some View {
        VStack {
            header
            ScrollView {
                if books.isEmpty {
                    ContentUnavailableView(
                        "No books have been added to \"\(status.title)\"",
                        systemImage: "book.closed"
                    )
                } else {
                    LazyVStack {
                        ForEach(books) { book in
                            BookView(book: book)
                        }
                    }
                }
            }
            .frame(maxWidth: horizontalSizeClass == .compact ? mainWindowSize.width : 370)
            .frame(maxHeight: horizontalSizeClass == .compact ? mainWindowSize.height : .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(Color(hexString: status.hexColorString, opacity: .low))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .sheet(isPresented: $isBarcodeScannerPresented) {
            BarcodeScannerView { barcode in
                guard let isbn = barcode.payloadStringValue, !isbn.hasPrefix("192") else {
                    return
                }
                recognizedIsbn = isbn
            }
            .ignoresSafeArea()
        }
        .task(id: recognizedIsbn) {
            defer { recognizedIsbn = nil }
            guard let recognizedIsbn else {
                return
            }
            await onRecognize(isbn: recognizedIsbn)
        }
        .alert("An error has occurred", isPresented: $isErrorAlertPresented, presenting: localizedError) { error in
            Button("OK", role: .cancel) {
            }
        }
        .sheet(item: $scannedBook) { book in
            NavigationStack {
                AddBookView(status: status, viewType: .book(book))
            }
        }
        .sheet(isPresented: $isAddBookViewPresented) {
            NavigationStack {
                AddBookView(status: status, viewType: .original)
            }
        }
        .task {
            await fetchBooks()
        }
    }

    var header: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hexString: status.hexColorString, opacity: .solid))
                    .frame(width: 12, height: 12)
                Text(status.title)
                    .font(.title3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hexString: status.hexColorString, opacity: .medium))
            .clipShape(Capsule())

            Text(books.count.description)
                .font(.headline)
                .foregroundStyle(Color(hexString: status.hexColorString, opacity: .medium))

            Spacer()

            HStack(alignment: .center) {
                Menu {
                    Button("Read barcode", systemImage: "barcode.viewfinder") {
                        isBarcodeScannerPresented = true
                    }
                    Button("Search for books", systemImage: "text.page.badge.magnifyingglass") {}
                    Button("Add a custom book", systemImage: "book.closed") {}
                } label: {
                    Image(systemName: "plus")
                        .padding(8)
                }

                Menu {
                    Button("Rename", systemImage: "pencil") {}
                    Button("Delete all", systemImage: "trash", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(8)
                }
            }
            .tint(.primary)
        }
    }

    private func fetchBooks() async {
        do {
            let id = status.id
            let books = try modelContext.fetch(
                FetchDescriptor<Book>(
                    predicate: #Predicate {
                        $0.status.id == id
                    },
                    sortBy: [
                        SortDescriptor(\.priority)
                    ]
                )
            )
            self.books = books.map { $0.toEntity() }
        } catch {}
    }

    private func onRecognize(isbn: String) async {
        do {
            let book = try await GoogleBooksClient().getBook(isbn: isbn)
            isBarcodeScannerPresented = false
            scannedBook = book
        } catch let error as GoogleBooksClient.Error {
            showError(error: error)
        } catch {
            showError(error: BooklogError.requestError)
        }
    }

    private func showError(error: any LocalizedError) {
        isErrorAlertPresented = true
        localizedError = error
    }
}
