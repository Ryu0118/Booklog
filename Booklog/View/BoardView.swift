import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let board: Board
    let status: [Status]

    init(board: Board) {
        self.board = board
        self.status = board.status.sorted(by: { $0.priority < $1.priority })
    }

    var body: some View {
        let Stack = horizontalSizeClass == .compact ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
        let axis: Axis.Set = horizontalSizeClass == .compact ? .vertical : .horizontal
        ScrollView(axis, showsIndicators: horizontalSizeClass != .compact) {
            Stack {
                ForEach(status) { status in
                    StatusView(status: status)
                }
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
    }
}
