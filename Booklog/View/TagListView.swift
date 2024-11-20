import SwiftUI

struct TagListView: View {
    let tags: [Tag]

    var body: some View {
        FlowLayout(alignment: .leading, spacing: 7) {
            ForEach(tags) { tag in
                Text(tag.name)
                    .foregroundStyle(Color(hexString: tag.hexColorString, opacity: 1))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(Color(hexString: tag.hexColorString, opacity: 0.2))
                    .cornerRadius(15)
            }
        }
    }
}
