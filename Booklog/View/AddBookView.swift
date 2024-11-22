import SwiftUI
import PhotosUI
import SwiftData

struct AddBookView: View {
    enum Const {
        static let thumbnailWidth: CGFloat = 150
        static let thumbnailHeight: CGFloat = 211
    }
    enum ViewType {
        case original
        case book(GoogleBooksClient.FormattedResponse)
    }

    enum FieldType: Equatable {
        case title, pageCount
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var book: Book.Entity
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var photoPickedImage: UIImage?
    @State private var isDeadlineEnabled: Bool = false
    @FocusState private var focusedField: FieldType?

    var saveButtonDisabled: Bool {
        book.title.isEmpty ||
        otherBooksTitles.contains(book.title) ||
        book.title.count > 100 ||
        (book.bookDescription?.count ?? 0) > 1000
    }

    private let status: Status
    private let otherBooksTitles: [String]

    init(
        status: Status,
        viewType: ViewType
    ) {
        self.otherBooksTitles = status.books.map(\.title)
        self.status = status
        let now = Date()
        switch viewType {
        case .original:
            self.book = Book.Entity(
                id: UUID(),
                tags: [],
                title: "",
                priority: status.books.count,
                createdAt: now,
                updatedAt: now
            )
        case .book(let formattedResponse):
            self.book = Book.Entity(
                id: UUID(),
                tags: [],
                title: formattedResponse.title,
                priority: status.books.count,
                authors: formattedResponse.authors,
                publisher: formattedResponse.publisher,
                publishedDate: formattedResponse.publishedDate,
                bookDescription: formattedResponse.description,
                smallThumbnail: formattedResponse.smallThumbnail,
                thumbnail: formattedResponse.thumbnail,
                deadline: nil,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    @MainActor
    var body: some View {
        List {
            thumbnail

            TextField("Title", text: $book.title, prompt: Text("Enter a book title"))
                .focused($focusedField, equals: .title)

            Section("Description") {
                TextEditor(
                    text: Binding<String>(
                        get: { book.bookDescription ?? "" },
                        set: { book.bookDescription = $0 }
                    )
                )
            }

            deadline

            pageCount

            Section("Tag") {
                NavigationLink {
                    SelectTagView(book: $book)
                } label: {
                    Group {
                        if book.tags.isEmpty {
                            Text("No tags have been added")
                                .foregroundStyle(.secondary)
                        } else {
                            TagListView(tags: book.tags)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Add book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveBook()
                }
                .disabled(saveButtonDisabled)
            }
        }
        .onChange(of: photoPickerItems) { old, new in
            if let photoPickerItem = photoPickerItems.first {
                Task {
                    if let loadedImage = try await photoPickerItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: loadedImage)
                    {
                        book.thumbnailData = uiImage.pngData()
                        photoPickedImage = uiImage
                    }
                }
            }
        }
    }

    private var thumbnail: some View {
        PhotosPicker(
            selection: $photoPickerItems,
            maxSelectionCount: 1,
            selectionBehavior: .ordered,
            matching: .images,
            preferredItemEncoding: .current,
            photoLibrary: .shared()
        ) { [thumbnailURL = book.thumbnailURL ?? BooklogConst.noImageThumbnailURL, photoPickedImage] in
            Group {
                if let photoPickedImage {
                    Image(uiImage: photoPickedImage).thumbnail()
                } else {
                    AsyncImage(url: thumbnailURL) { image in
                        image.thumbnail()
                    } placeholder: {
                        Rectangle().fill(.gray)
                            .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                    }
                }
            }
            .centered(.horizontal)
        }
    }

    private var pageCount: some View {
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
            .keyboardType(.numbersAndPunctuation)
            .focused($focusedField, equals: .pageCount)
            .onSubmit(of: .text) {
                focusedField = nil
            }
        }
    }

    private var deadline: some View {
        Section("Deadline") {
            Toggle(
                "Enable",
                isOn: Binding<Bool>(
                    get: { isDeadlineEnabled },
                    set: {
                        if !$0 {
                            book.deadline = nil
                        }
                        isDeadlineEnabled = $0
                    }
                )
            )

            if isDeadlineEnabled {
                let now = Date()
                DatePicker(
                    "Deadline",
                    selection: Binding<Date>(
                        get: { book.deadline ?? now },
                        set: { book.deadline = $0 }
                    ),
                    in: Calendar.current.date(byAdding: .day, value: 1, to: now)! ... Calendar.current.date(byAdding: .day, value: 9999, to: now)!,
                    displayedComponents: [.date]
                )
            }
        }
    }

    private func saveBook() {
        do {
            let ids = book.tags.map(\.id)
            let tags = try modelContext.fetch(
                FetchDescriptor<Tag>(predicate: #Predicate {
                    ids.contains($0.id)
                })
            )

            let book = book.toOriginalModel(status: status, tags: tags, comments: [])
            modelContext.insert(book)
            try modelContext.save()
            dismiss()
        } catch {}
    }
}

fileprivate extension Image {
    func thumbnail() -> some View  {
        self
            .resizable()
            .scaledToFit()
            .frame(width: AddBookView.Const.thumbnailWidth, height: AddBookView.Const.thumbnailHeight)
    }
}
