import SwiftUI

struct BookView: View {
    enum Const {
        static let thumbnailWidth: CGFloat = 55
        static let thumbnailHeight: CGFloat = 78
    }
    let book: Book.Entity

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let imageData = book.thumbnailData,
                   let uiImage = UIImage(data: imageData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                } else {
                    AsyncImage(url: book.thumbnailURL) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                    } placeholder: {
                        Rectangle().fill(Color.gray)
                            .frame(width: Const.thumbnailWidth, height: Const.thumbnailHeight)
                    }
                }

                Text(book.title)
                    .font(.headline)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            if let readData = book.readData {
                ProgressView(
                    "Page \(readData.currentPage) / \(readData.totalPage) (\(Decimal.FormatStyle.Percent().format(Decimal(readData.progress))))",
                    value: readData.progress
                )
                .font(.caption)
            }

            TagListView(tags: book.tags)
        }
        .padding()
        .background(Color.background)
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
                    name: "Swift",
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
                    name: "Swift",
                    hexColorString: "6B94B7",
                    createdAt: .now,
                    updatedAt: .now
                ),
                Tag.Entity(
                    id: UUID(),
                    name: "Swift",
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
