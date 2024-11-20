import SwiftUI

struct TagListView: View {
    let tags: [Tag.Entity]
    let selectedTags: Set<Tag.Entity>

    let onTapGesture: ((Tag.Entity) -> Void)?
    let onLongPressGesture: ((Tag.Entity) -> Void)?

    init(
        tags: [Tag.Entity],
        selectedTags: Set<Tag.Entity> = [],
        onTapGesture: ((Tag.Entity) -> Void)? = nil,
        onLongPressGesture: ((Tag.Entity) -> Void)? = nil
    ) {
        self.tags = tags
        self.selectedTags = selectedTags
        self.onTapGesture = onTapGesture
        self.onLongPressGesture = onLongPressGesture
    }

    var body: some View {
        FlowLayout(alignment: .leading, spacing: 7) {
            ForEach(tags) { tag in
                Text(tag.name)
                    .foregroundStyle(Color(hexString: tag.hexColorString, opacity: 1))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(Color(hexString: tag.hexColorString, opacity: 0.2))
                    .cornerRadius(15)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color(hexString: tag.hexColorString, opacity: selectedTags.contains(tag) ? 1 : 0), lineWidth: 1)
                    }
                    .onTapGesture {
                        onTapGesture?(tag)
                    }
                    .onLongPressGesture {
                        onLongPressGesture?(tag)
                    }
            }
        }
    }
}
