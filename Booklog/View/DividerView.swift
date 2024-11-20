import SwiftUI

struct DividerView<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group(subviews: content) { subviews in
            ForEach(subviews: subviews) { subview in
                subview
                if subview.id != subviews.last?.id {
                    Divider()
                }
            }
        }
    }
}
