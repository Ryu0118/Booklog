import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let boardName: String
    @Query var status: [Status]

    init(board: Board) {
        self.boardName = board.name
        let id = board.id
        _status = Query(
            filter: #Predicate {
                $0.parentBoard?.id == id
            },
            sort: [
                SortDescriptor(\.priority)
            ],
            animation: .easeInOut
        )
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
        .navigationTitle(boardName)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
    }
}
