import SwiftUI

struct BookView: View {
    let book: Book.Entity

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: book.thumbnailURL) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 78)
                } placeholder: {
                    Rectangle().fill(Color.gray)
                        .frame(width: 55, height: 78)
                }

                Text(book.title)
                    .font(.headline)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            TagListView(tags: book.tags)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Normal") {
    BookView(
        book: Book.Entity(
            id: UUID(),
            tags: [
                Tag.Entity(
                    id: UUID(),
                    name: "Swift", books: [],
                    hexColorString: "6B94B7",
                    createdAt: .now,
                    updatedAt: .now
                )
            ],
            title: "Mathematics Book",
            priority: 0,
            createdAt: .now,
            updatedAt: .now
        )
    )
}

#Preview("Long") {
    BookView(
        book: Book.Entity(
            id: UUID(),
            tags: [
                Tag.Entity(
                    id: UUID(),
                    name: "Swift", books: [],
                    hexColorString: "6B94B7",
                    createdAt: .now,
                    updatedAt: .now
                ),
                Tag.Entity(
                    id: UUID(),
                    name: "Swift", books: [],
                    hexColorString: "8460CC",
                    createdAt: .now,
                    updatedAt: .now
                )
            ],
            title: "Mathematics Book\nMathematics Book\nMathematics Book\nMathematics Book",
            priority: 0,
            createdAt: .now,
            updatedAt: .now
        )
    )
}
