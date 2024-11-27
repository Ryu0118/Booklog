import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    @State private var newStatusName = ""
    @State private var newBoardName = ""
    @State private var isNewStatusNameFieldPresented = false
    @State private var isErrorAlertPresented = false
    @State private var presentingError: (any LocalizedError)?
    @State private var isRenameBoardAlertPresented = false
    @State private var isBoardDeleting = false

    var newStatusNameOKButtonDisabled: Bool {
        board.status.lazy.map(\.title).contains(newStatusName) || newStatusName.isEmpty || newStatusName.count > 20
    }

    var newBoardButtonDisabled: Bool {
        newBoardName.isEmpty || allBoardTitles.contains(newBoardName)
    }

    let board: Board
    let allBoardTitles: [String]
    @Query var status: [Status]

    init(board: Board, allBoardTitles: [String]) {
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
        self.allBoardTitles = allBoardTitles
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
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        isRenameBoardAlertPresented = true
                    }
                    Button("Delete \"\(board.name)\"", systemImage: "trash", role: .destructive) {
                        isBoardDeleting = true
                    }
                    .disabled(allBoardTitles.count == 1)
                } label: {
                    Image(systemName: "ellipsis")
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
        .alert("Rename", isPresented: $isRenameBoardAlertPresented) {
            TextField("Enter a new board name", text: $newBoardName)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                do {
                    try modelContext.transaction {
                        board.name = newBoardName
                    }
                } catch {
                    showError(BooklogError.unknownError)
                }
            }
            .disabled(newBoardButtonDisabled)
        }
        .alert("An error has occurred", isPresented: $isErrorAlertPresented, presenting: presentingError) { error in
            Button("OK", role: .cancel) {
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Do you really want to delete \"\(board.name)\"?", isPresented: $isBoardDeleting) {
            Button("Yes", role: .destructive) {
                do {
                    try modelContext.transaction {
                        modelContext.delete(board)
                    }
                } catch {
                    showError(BooklogError.unknownError)
                }
            }
        }
    }

    private func showError(_ error: any LocalizedError) {
        isErrorAlertPresented = true
        presentingError = error
    }
}
