import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    @State private var newStatusName = ""
    @State private var isNewStatusNameFieldPresented = false
    @State private var isErrorAlertPresented = false
    @State private var presentingError: (any LocalizedError)?

    var newStatusNameOKButtonDisabled: Bool {
        board.status.lazy.map(\.title).contains(newStatusName) || newStatusName.isEmpty || newStatusName.count > 20
    }

    let board: Board
    @Query var status: [Status]

    init(board: Board) {
        self.board = board
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
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") {
                    isNewStatusNameFieldPresented = true
                }
            }
        }
        .alert("Create a new status", isPresented: $isNewStatusNameFieldPresented) {
            TextField("Enter a new status name", text: $newStatusName)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                do {
                    try modelContext.transaction {
                        let now = Date()
                        modelContext.insert(
                            Status(
                                id: UUID(),
                                books: [],
                                parentBoard: board,
                                title: newStatusName,
                                priority: board.status.count,
                                hexColorString: Color.random().hexString(),
                                createdAt: now,
                                updatedAt: now
                            )
                        )
                    }
                } catch {
                    showError(BooklogError.unknownError)
                }
            }
            .disabled(newStatusNameOKButtonDisabled)
        }
        .alert("An error has occurred", isPresented: $isErrorAlertPresented, presenting: presentingError) { error in
            Button("OK", role: .cancel) {
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func showError(_ error: any LocalizedError) {
        isErrorAlertPresented = true
        presentingError = error
    }
}
