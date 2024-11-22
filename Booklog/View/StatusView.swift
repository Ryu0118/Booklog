import SwiftUI
import SwiftData
import CoreTransferable

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
    @State private var books: [Book.Entity] = []
    @State private var vstackHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0

    private let bookClient = BookClient()
    private let statusClient = StatusClient()

    let status: Status

    var body: some View {
        VStack {
            header
            ScrollView {
                LazyVStack {
                    core
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    vstackHeight = $0
                }
                .padding(.bottom, horizontalSizeClass == .compact ? 0 : scrollViewHeight - vstackHeight)
                .frame(width: horizontalSizeClass == .compact ? mainWindowSize.width : 350)
                .frame(maxHeight: horizontalSizeClass == .compact ? mainWindowSize.height : .infinity)
                .contentShape(Rectangle())
                .dropDestination(for: BookDraggableData.self) { draggableData, location in
                    let isRefreshRequired = draggableData.lazy.map {
                        move(
                            fromBookID: $0.bookID,
                            fromStatusID: $0.statusID,
                            toBookID: books.last?.id,
                            toStatusID: status.id,
                            insertLast: true
                        )
                    }
                        .allSatisfy { $0 }
                    if isRefreshRequired {
                        NotificationCenter.default.post(name: .reloadStatus, object: nil)
                    }
                    return isRefreshRequired
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: {
                scrollViewHeight = $0
            }
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
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(item: $scannedBook) { book in
            NavigationStack {
                AddBookView(status: status, viewType: .book(book)) {
                    fetchAndApplyBooks()
                }
            }
        }
        .sheet(isPresented: $isAddBookViewPresented) {
            NavigationStack {
                AddBookView(status: status, viewType: .original) {
                    fetchAndApplyBooks()
                }
            }
        }
        .onAppear {
            fetchAndApplyBooks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadStatus)) { _ in
            fetchAndApplyBooks()
        }
    }

    @ViewBuilder
    var core: some View {
        if books.isEmpty {
            ContentUnavailableView(
                "No books have been added to \"\(status.title)\"",
                systemImage: "book.closed"
            )
        } else {
            ForEach(books) { book in
                BookView(book: book)
                    .draggable(
                        BookDraggableData(
                            bookID: book.id,
                            statusID: status.id
                        )
                    )
                    .dropDestination(for: BookDraggableData.self) { draggableData, location in
                        let isRefreshRequired = draggableData.lazy.map {
                            move(
                                fromBookID: $0.bookID,
                                fromStatusID: $0.statusID,
                                toBookID: book.id,
                                toStatusID: status.id
                            )
                        }
                        .allSatisfy { $0 }
                        if isRefreshRequired { NotificationCenter.default.post(name: .reloadStatus, object: nil) }
                        return isRefreshRequired
                    }
            }
        }
    }

    var header: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hexString: status.hexColorString, opacity: .solid))
                    .frame(width: 12, height: 12)
                Text(status.title)
                    .font(.headline)
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
                    Button("Add a custom book", systemImage: "book.closed") {
                        isAddBookViewPresented = true
                    }
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

    private func move(
        fromBookID sourceBookID: Book.ID,
        fromStatusID sourceStatusID: Status.ID,
        toBookID destinationBookID: Book.ID?,
        toStatusID destinationStatusID: Status.ID,
        insertLast: Bool = false
    ) -> Bool {
        // 1, 2, 3, 4, 5
        // 1, 2, 5, 3, 4
        // 1, 2, 3, 4, 5
        guard sourceBookID != destinationBookID else {
            return false
        }

        do {
            if sourceStatusID == destinationStatusID {
                var books = try fetchBooks()
                guard let sourceBookIndex = books.firstIndex(where: { $0.id == sourceBookID }),
                      let destinationBookIndex = books.firstIndex(where: { $0.id == destinationBookID })
                else {
                    return false
                }
                try modelContext.transaction {
                    let sourceBook = books[sourceBookIndex]
                    books.remove(at: sourceBookIndex)
                    if insertLast {
                        books.append(sourceBook)
                    } else {
                        books.insert(sourceBook, at: destinationBookIndex)
                    }
                    books.enumerated().forEach { index, book in
                        book.priority = index
                    }
                }
            } else if destinationBookID == nil {
                let book = try bookClient.fetchBook(id: sourceBookID, modelContext: modelContext)
                let status = try statusClient.fetchStatus(id: destinationStatusID, modelContext: modelContext)
                try modelContext.transaction {
                    book.status = status
                    book.priority = 0

                    let books = try fetchBooks()
                    books.enumerated().forEach { index, book in
                        book.priority = index
                    }
                }
            } else {
                var books = try fetchBooks(for: sourceStatusID)
                var destinationStatusBooks = try fetchBooks(for: destinationStatusID)
                let destinationStatus = try statusClient.fetchStatus(id: destinationStatusID, modelContext: modelContext)
                guard let sourceBookIndex = books.firstIndex(where: { $0.id == sourceBookID }),
                      let destinationBookIndex = destinationStatusBooks.firstIndex(where: { $0.id == destinationBookID })
                else {
                    return false
                }
                let sourceBook = books[sourceBookIndex]
                try modelContext.transaction {
                    sourceBook.status = destinationStatus
                    books.remove(at: sourceBookIndex)
                    books.enumerated().forEach { index, book in
                        book.priority = index
                    }
                    if insertLast {
                        destinationStatusBooks.append(sourceBook)
                    } else {
                        destinationStatusBooks.insert(sourceBook, at: destinationBookIndex)
                    }
                    destinationStatusBooks.enumerated().forEach { index, book in
                        book.priority = index
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }

    private func fetchBooks() throws -> [Book] {
        let id = status.id
        return try bookClient.fetchBooks(for: id, modelContext: modelContext)
    }

    private func fetchBooks(for statusID: Status.ID) throws -> [Book] {
        return try bookClient.fetchBooks(for: statusID, modelContext: modelContext)
    }

    private func fetchAndApplyBooks() {
        do {
            self.books = try fetchBooks().map { $0.toEntity() }
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

    struct BookDraggableData: Transferable, Codable {
        let bookID: Book.ID
        let statusID: Status.ID

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(for: BookDraggableData.self, contentType: .data)
        }
    }
}
