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
    @State private var vstackHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var isRenameStatusNameAlertPresented = false
    @State private var newStatusName: String
    @State private var isAllDeleting = false
    @State private var isColorPalettePresented = false
    @State private var isDialogPresented = false
    @State private var editingBook: Book?
    @State private var deletingBook: Book?
    @State private var focusedBook: Book.Entity?
    @State private var isConfirmDeleteAlertPresented = false
    @State private var isCurrentNumberOfPagesFieldPresented = false
    @State private var isStatusDeleting = false
    @State private var isBookSearchViewPresented = false

    private let bookClient = BookClient()
    private let statusClient = StatusClient()

    let status: Status

    @Query var books: [Book]

    var bookEntities: [Book.Entity] {
        books.map { $0.toEntity() }
    }

    var newStatusNameOKButtonDisabled: Bool {
        status.parentBoard?.status.lazy.map(\.title).contains(newStatusName) ?? false || newStatusName.isEmpty || newStatusName.count > 20
    }

    var currentNumberOfPagesFieldDisabled: Bool {
        if let readData = focusedBook?.readData {
            readData.currentPage > readData.totalPage ||
            readData.currentPage < 0
        } else {
            false
        }
    }

    init(status: Status) {
        self.status = status
        let id = status.id
        _books = Query(
            filter: #Predicate {
                $0.status.id == id
            },
            sort: [
                SortDescriptor(\.priority)
            ],
            animation: .easeInOut
        )
        newStatusName = status.title
    }

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
                .padding(.bottom, horizontalSizeClass == .compact ? 0 : max(0, scrollViewHeight - vstackHeight))
                .frame(width: horizontalSizeClass == .compact ? mainWindowSize.width : 350)
                .contentShape(Rectangle())
                .dropDestination(for: DraggableData.self) { draggableData, location in
                    draggableData.lazy.map {
                        switch $0 {
                        case .book(let data):
                            move(
                                fromBookID: data.bookID,
                                fromStatusID: data.statusID,
                                toBookID: bookEntities.last?.id,
                                toStatusID: status.id,
                                insertLast: true
                            )
                        case .status(let sourceStatus):
                            move(
                                fromStatusID: sourceStatus.statusID,
                                toStatusID: status.id
                            )
                        }
                    }
                    .allSatisfy { $0 }
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
                AddBookView(status: status, viewType: .new(.book(book)))
            }
        }
        .sheet(isPresented: $isAddBookViewPresented) {
            NavigationStack {
                AddBookView(status: status, viewType: .new(.original))
            }
        }
        .sheet(item: $editingBook) { book in
            NavigationStack {
                AddBookView(status: status, viewType: .edit(book))
            }
        }
        .alert("Rename", isPresented: $isRenameStatusNameAlertPresented) {
            TextField("Enter a new status name", text: $newStatusName)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                newStatusNameAlertOKButtonTapped()
            }
            .disabled(newStatusNameOKButtonDisabled)
        }
        .alert("Do you really want to delete all of them?", isPresented: $isAllDeleting) {
            Button("Yes", role: .destructive) {
                deleteAllBooksButtonTapped()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Do you really want to delete this book?", isPresented: $isConfirmDeleteAlertPresented, presenting: deletingBook) { book in
            Button("Yes", role: .destructive) {
                deleteBookButtonTapped(for: book)
            }
        }
        .alert("Do you really want to delete \"\(status.title)\"?", isPresented: $isStatusDeleting) {
            Button("Yes", role: .destructive) {
                deleteStatusButtonTapped()
            }
        } message: {
            Text("All books in \"\(status.title)\" will be deleted.")
        }
        .alert("Enter the current number of pages", isPresented: $isCurrentNumberOfPagesFieldPresented, presenting: focusedBook) { focusedBook in
            if let readData = focusedBook.readData {
                TextField(
                    "",
                    text: Binding<String>(
                        get: { readData.currentPage.description },
                        set: {
                            if let page = Int($0) {
                                self.focusedBook?.readData?.currentPage = page
                            }
                        }
                    )
                )
                .keyboardType(.numberPad)

                Button("OK") {
                    changeCurrentNumberOfPages(of: focusedBook, readData: self.focusedBook?.readData ?? readData)
                }
                .disabled(currentNumberOfPagesFieldDisabled)

                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $isColorPalettePresented) {
            ColorPickerWellView(
                selectedColor: Color(hexString: status.hexColorString),
                onColorPicked: {
                    onColorSelected($0)
                }
            )
        }
        .sheet(isPresented: $isBookSearchViewPresented) {
            BookSearchView(status: status)
        }
        .draggable(StatusDraggableData(statusID: status.id))
        .dropDestination(for: DraggableData.self) { draggableData, location in
            draggableData.lazy.map {
                switch $0 {
                case .book(let data):
                    move(
                        fromBookID: data.bookID,
                        fromStatusID: data.statusID,
                        toBookID: bookEntities.last?.id,
                        toStatusID: status.id
                    )
                case .status(let sourceStatus):
                    move(
                        fromStatusID: sourceStatus.statusID,
                        toStatusID: status.id
                    )
                }
            }
            .allSatisfy { $0 }
        }
    }

    @ViewBuilder
    var core: some View {
        if bookEntities.isEmpty {
            ContentUnavailableView(
                "No books have been added to \"\(status.title)\"",
                systemImage: "book.closed"
            )
        } else {
            ForEach(bookEntities) { book in
                Button {
                    isDialogPresented = true
                    focusedBook = book
                } label: {
                    BookView(book: book)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .confirmationDialog("", isPresented: $isDialogPresented, presenting: focusedBook) { bookEntity in
                    if bookEntity.readData != nil {
                        Button("Enter the current number of pages") {
                            isCurrentNumberOfPagesFieldPresented = true
                        }
                    }
                    Button("Edit") {
                        do {
                            let book = try bookClient.fetchBook(id: bookEntity.id, modelContext: modelContext)
                            editingBook = book
                        } catch {}
                    }
                    Button("Delete", role: .destructive) {
                        do {
                            let book = try bookClient.fetchBook(id: bookEntity.id, modelContext: modelContext)
                            isConfirmDeleteAlertPresented = true
                            deletingBook = book
                        } catch {}
                    }
                }
                .draggable(
                    BookDraggableData(
                        bookID: book.id,
                        statusID: status.id
                    )
                )
                .dropDestination(for: DraggableData.self) { draggableData, location in
                    draggableData.lazy.map {
                        switch $0 {
                        case .book(let data):
                            move(
                                fromBookID: data.bookID,
                                fromStatusID: data.statusID,
                                toBookID: book.id,
                                toStatusID: status.id
                            )
                        case .status(let sourceStatus):
                            move(
                                fromStatusID: sourceStatus.statusID,
                                toStatusID: status.id
                            )
                        }
                    }
                    .allSatisfy { $0 }
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

            Text(bookEntities.count.description)
                .font(.headline)
                .foregroundStyle(Color(hexString: status.hexColorString, opacity: .medium))

            Spacer()

            HStack(alignment: .center) {
                Menu {
                    Button("Read barcode", systemImage: "barcode.viewfinder") {
                        isBarcodeScannerPresented = true
                    }
                    Button("Search for books", systemImage: "text.page.badge.magnifyingglass") {
                        isBookSearchViewPresented = true
                    }
                    Button("Add a custom book", systemImage: "book.closed") {
                        isAddBookViewPresented = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .padding(8)
                }

                Menu {
                    Button("Rename", systemImage: "pencil") {
                        isRenameStatusNameAlertPresented = true
                    }
                    Button("Change color theme", systemImage: "paintpalette") {
                        isColorPalettePresented = true
                    }
                    Button("Delete all books", systemImage: "trash", role: .destructive) {
                        isAllDeleting = true
                    }
                    .disabled(books.isEmpty)
                    Button("Delete \"\(status.title)\"", systemImage: "trash", role: .destructive) {
                        isStatusDeleting = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(8)
                }
            }
            .tint(.primary)
        }
    }

    private func newStatusNameAlertOKButtonTapped() {
        do {
            try modelContext.transaction {
                status.title = newStatusName
            }
            newStatusName = status.title
        } catch {
            showError(error: BooklogError.unknownError)
        }
    }

    private func move(
        fromStatusID sourceStatusID: Status.ID,
        toStatusID destinationStatusID: Status.ID
    ) -> Bool {
        guard sourceStatusID != destinationStatusID else {
            return false
        }

        do {
            let sourceStatus = try statusClient.fetchStatus(id: sourceStatusID, modelContext: modelContext)
            let destinationStatus = try statusClient.fetchStatus(id: destinationStatusID, modelContext: modelContext)

            guard let sourceParentBoard = sourceStatus.parentBoard,
                  let destinationParentBoard = destinationStatus.parentBoard
            else {
                return false
            }

            var sourceStatuses = sourceParentBoard.status.sorted(by: { $0.priority < $1.priority })
            var destinationStatuses = destinationParentBoard.status.sorted(by: { $0.priority < $1.priority })

            guard let sourceStatusIndex = sourceStatuses.firstIndex(of: sourceStatus),
                  let destinationStatusIndex = destinationStatuses.firstIndex(of: destinationStatus)
            else {
                return false
            }

            if sourceParentBoard.id == destinationParentBoard.id {
                sourceStatuses.remove(at: sourceStatusIndex)
                sourceStatuses.insert(sourceStatus, at: destinationStatusIndex)

                try modelContext.transaction {
                    for (index, status) in sourceStatuses.enumerated() {
                        status.priority = index
                    }
                }
            } else {
                try modelContext.transaction {
                    sourceStatuses.remove(at: sourceStatusIndex)
                    destinationStatuses.insert(sourceStatus, at: destinationStatusIndex)

                    sourceStatus.parentBoard = destinationStatus.parentBoard

                    for (index, status) in sourceStatuses.enumerated() {
                        status.priority = index
                    }
                    for (index, status) in destinationStatuses.enumerated() {
                        status.priority = index
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }

    private func move(
        fromBookID sourceBookID: Book.ID,
        fromStatusID sourceStatusID: Status.ID,
        toBookID destinationBookID: Book.ID?,
        toStatusID destinationStatusID: Status.ID,
        insertLast: Bool = false
    ) -> Bool {
        guard sourceBookID != destinationBookID else {
            return false
        }

        do {
            if sourceStatusID == destinationStatusID {
                var bookEntities = try fetchBooks()
                guard let sourceBookIndex = bookEntities.firstIndex(where: { $0.id == sourceBookID }),
                      let destinationBookIndex = bookEntities.firstIndex(where: { $0.id == destinationBookID })
                else {
                    return false
                }
                try modelContext.transaction {
                    let sourceBook = bookEntities[sourceBookIndex]
                    bookEntities.remove(at: sourceBookIndex)
                    if insertLast {
                        bookEntities.append(sourceBook)
                    } else {
                        bookEntities.insert(sourceBook, at: destinationBookIndex)
                    }
                    bookEntities.enumerated().forEach { index, book in
                        book.priority = index
                    }
                }
            } else if destinationBookID == nil {
                let book = try bookClient.fetchBook(id: sourceBookID, modelContext: modelContext)
                let status = try statusClient.fetchStatus(id: destinationStatusID, modelContext: modelContext)
                try modelContext.transaction {
                    book.status = status
                    book.priority = 0

                    let bookEntities = try fetchBooks()
                    bookEntities.enumerated().forEach { index, book in
                        book.priority = index
                    }
                }
            } else {
                var bookEntities = try fetchBooks(for: sourceStatusID)
                var destinationStatusBooks = try fetchBooks(for: destinationStatusID)
                let destinationStatus = try statusClient.fetchStatus(id: destinationStatusID, modelContext: modelContext)
                guard let sourceBookIndex = bookEntities.firstIndex(where: { $0.id == sourceBookID }),
                      let destinationBookIndex = destinationStatusBooks.firstIndex(where: { $0.id == destinationBookID })
                else {
                    return false
                }
                let sourceBook = bookEntities[sourceBookIndex]
                try modelContext.transaction {
                    sourceBook.status = destinationStatus
                    bookEntities.remove(at: sourceBookIndex)
                    bookEntities.enumerated().forEach { index, book in
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

    private func deleteAllBooksButtonTapped() {
        let statusID = status.id
        do {
            try modelContext.transaction {
                let booksToDelete = try modelContext.fetch(
                    FetchDescriptor<Book>(
                        predicate: #Predicate { $0.status.id == statusID }
                    )
                )

                for book in booksToDelete {
                    modelContext.delete(book)
                }
            }
        } catch {
            showError(error: BooklogError.unknownError)
        }
    }

    private func deleteBookButtonTapped(for book: Book) {
        do {
            try modelContext.transaction {
                modelContext.delete(book)
            }
        } catch {
            showError(error: BooklogError.unknownError)
        }
    }

    private func changeCurrentNumberOfPages(of focusedBook: Book.Entity, readData: Book.ReadData) {
        do {
            try modelContext.transaction {
                let book = try bookClient.fetchBook(id: focusedBook.id, modelContext: modelContext)
                book.readData = readData
            }
        } catch {
            showError(error: BooklogError.unknownError)
        }
        self.focusedBook = nil
    }

    private func deleteStatusButtonTapped() {
        do {
            try modelContext.transaction {
                modelContext.delete(status)
            }
        } catch {
            showError(error: BooklogError.unknownError)
        }
    }

    private func onColorSelected(_ uiColor: UIColor) {
        do {
            try modelContext.transaction {
                status.hexColorString = uiColor.hexString()
            }
        } catch {
            showError(error: BooklogError.unknownError)
        }
    }

    struct BookDraggableData: Transferable, Codable {
        let bookID: Book.ID
        let statusID: Status.ID

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(for: BookDraggableData.self, contentType: .book)
        }
    }

    struct StatusDraggableData: Transferable, Codable {
        let statusID: Status.ID

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(for: StatusDraggableData.self, contentType: .status)
        }
    }

    enum DraggableData: Transferable {
        case book(BookDraggableData)
        case status(StatusDraggableData)

        static var transferRepresentation: some TransferRepresentation {
            ProxyRepresentation(importing: { DraggableData.book($0) })
            ProxyRepresentation(importing: { DraggableData.status($0) })
        }
    }
}
