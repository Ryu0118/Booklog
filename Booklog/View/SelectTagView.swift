import SwiftUI
import SwiftData

struct SelectTagView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.createdAt, animation: .smooth) private var tags: [Tag]

    @Binding var book: Book.Entity
    @State private var isAddTagViewPresented = false
    @State private var isDialogPresented = false
    @State private var longPressedTag: Tag.Entity?
    @State private var tagToEdit: Tag.Entity?

    var body: some View {
        ScrollView {
            if tags.isEmpty {
                ContentUnavailableView("No tags have been added", image: "tag")
            } else {
                HStack(spacing: 0) {
                    TagListView(
                        tags: tags.map { $0.toEntity() },
                        selectedTags: Set(book.tags),
                        onTapGesture: { tag in
                            onTapTagGesture(tag)
                        },
                        onLongPressGesture: { tag in
                            onLongPressGesture(tag)
                        }
                    )
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") {
                    isAddTagViewPresented = true
                }
            }
        }
        .sheet(isPresented: $isAddTagViewPresented) {
            NavigationStack {
                AddTagView { _, tag in
                    addTag(tag)
                }
                .presentationSizing(.form)
            }
        }
        .sheet(item: $tagToEdit) { tag in
            NavigationStack {
                AddTagView(
                    tag: tag,
                    onTapAddButton: { oldTag, newTag in
                        if let oldTag {
                            updateTag(newTag, oldTag: oldTag)
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .confirmationDialog("", isPresented: $isDialogPresented, presenting: longPressedTag) { tag in
            Button("Edit") {
                tagToEdit = tag
            }
            Button("Delete", role: .destructive) {
                deleteButtonTapped(tag)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteButtonTapped(_ tag: Tag.Entity) {
        let id = tag.id
        try? modelContext.transaction {
            try? modelContext.delete(
                model: Tag.self,
                where: #Predicate<Tag> {
                    $0.id == id
                }
            )
        }
    }

    private func onLongPressGesture(_ tag: Tag.Entity) {
        isDialogPresented = true
        longPressedTag = tag
    }

    private func updateTag(_ tag: Tag.Entity, oldTag: Tag.Entity) {
        let oldTag = getOriginalTag(oldTag)

        try? modelContext.transaction {
            oldTag?.name = tag.name
            oldTag?.hexColorString = tag.hexColorString
            oldTag?.updatedAt = tag.updatedAt
        }
    }

    private func onTapTagGesture(_ tag: Tag.Entity) {
        if book.tags.contains(tag) {
            book.tags.removeAll(where: { $0.id == tag.id })
            book.updatedAt = .now
        } else {
            book.tags.append(tag)
            book.updatedAt = .now
        }
    }

    private func addTag(_ tag: Tag.Entity) {
        try? modelContext.transaction {
            modelContext.insert(
                Tag(
                    id: tag.id,
                    books: [],
                    name: tag.name,
                    hexColorString: tag.hexColorString,
                    createdAt: tag.createdAt,
                    updatedAt: tag.updatedAt
                )
            )
        }

        book.tags.append(tag)
        book.updatedAt = .now
    }

    private func getOriginalTag(_ entity: Tag.Entity) -> Tag? {
        let id = entity.id
        return try? modelContext.fetch(
            FetchDescriptor<Tag>(predicate: #Predicate {
                $0.id == id
            })
        ).first
    }
}

private struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss

    @State var tagTitle: String
    @State var color: Color

    var oldTag: Tag.Entity?

    init(
        tag: Tag.Entity,
        onTapAddButton: @escaping (_ oldTag: Tag.Entity?, _ newTag: Tag.Entity) -> Void
    ) {
        self.oldTag = tag
        self.tagTitle = tag.name
        self.color = Color(hexString: tag.hexColorString)
        self.onTapAddButton = onTapAddButton
    }

    init(
        tagTitle: String? = nil,
        hexColorString: String? = nil,
        onTapAddButton: @escaping (_ oldTag: Tag.Entity?, _ newTag: Tag.Entity) -> Void
    ) {
        self.tagTitle = tagTitle ?? ""
        self.onTapAddButton = onTapAddButton
        self.color = if let hexColorString {
            Color(hexString: hexColorString)
        } else {
            .random()
        }
    }

    let onTapAddButton: (_ oldTag: Tag.Entity?, _ newTag: Tag.Entity) -> Void

    var body: some View {
        Form {
            TextField("", text: $tagTitle, prompt: Text("Enter a tag title"))
            ColorPicker("Color", selection: $color, supportsOpacity: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    addButtonTapped()
                }
            }
        }
    }

    private func addButtonTapped() {
        let now = Date()
        let tag = Tag.Entity(
            id: UUID(),
            name: tagTitle,
            hexColorString: color.hexString(),
            createdAt: now,
            updatedAt: now
        )
        onTapAddButton(oldTag, tag)
        dismiss()
    }
}
