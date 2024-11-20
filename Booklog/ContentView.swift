import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedBoardID") private var selectedBoardID: String?
    @Query(sort: \Board.priority, animation: .smooth) private var boards: [Board]
    @State private var selectedBoard: Board?
    @State private var isTextFieldAlertPresented = false
    @State private var newBoardName = ""
    @State private var isTargeted: Bool = false
    @State private var isDeleteConfirmationAlertPresented = false
    @State private var boardToDelete: Board?

    var body: some View {
        NavigationSplitView {
            List(
                boards,
                id: \.id,
                selection: Binding<Board?>(
                    get: { selectedBoard },
                    set: { board in
                        selectBoard(board)
                    }
                )
            ) { board in
                NavigationLink(value: board) {
                    Label(board.name, systemImage: "square.on.square")
                }
                .swipeActions(edge: .trailing) {
                    if boards.count > 1 {
                        Button("Delete", systemImage: "trash") {
                            boardDeleteButtonTapped(board: board)
                        }
                        .tint(.red) // roleをdestructiveにするとalertが出る前にcellが削除されてしまう
                    }
                }
                if boards.last == board {
                    Section("Other") {
                        Label("[Source Code](https://github.com/Ryu0118/Booklog)", systemImage: "text.word.spacing")
                            .tint(.primary)
                        Label("[Other Apps](https://apps.apple.com/jp/developer/ryunosuke-shibuya/id1588660637)", systemImage: "app.gift")
                            .tint(.primary)
                    }
                }
            }
            .navigationTitle("Booklog")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isTextFieldAlertPresented = true
                    } label: {
                        Image(systemName: "plus.square.on.square")
                    }
                }
            }
            .alert("Create a new board", isPresented: $isTextFieldAlertPresented) {
                TextField("Enter a new board name", text: $newBoardName)
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    createNewBoardOKButtonTapped()
                }
                .disabled(newBoardName.isEmpty)
            }
            .alert("Are you sure you want to delete ‘\(boardToDelete?.name ?? "Board")’ completely?", isPresented: $isDeleteConfirmationAlertPresented) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let boardToDelete {
                        confirmDeleteBoard(board: boardToDelete)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        } detail: {
            if let selectedBoard {
                NavigationStack {
                    BoardView(board: selectedBoard)
                }
            }
        }
        .onAppear {
            if boards.isEmpty {
                initializeBoard()
            }
            if selectedBoard == nil {
                selectedBoard = boards.first(where: { $0.id.uuidString == selectedBoardID })
            }
        }
    }

    private func confirmDeleteBoard(board: Board) {
        defer {
            isDeleteConfirmationAlertPresented = false
            boardToDelete = nil
        }

        try? modelContext.transaction {
            modelContext.delete(board)
            for (index, board) in boards.lazy.filter({ $0.id == board.id }).enumerated() {
                board.priority = index
            }
        }

        if selectedBoardID == board.id.uuidString {
            selectBoard(boards.first)
        }
    }

    private func boardDeleteButtonTapped(board: Board) {
        boardToDelete = board
        isDeleteConfirmationAlertPresented = true
    }

    private func createNewBoardOKButtonTapped() {
        let board = createNewBoard(name: newBoardName)
        selectBoard(board)
        newBoardName = ""
    }

    @discardableResult
    private func createNewBoard(name: String) -> Board {
        let now = Date()
        let statuses = Status.createDefaultStatuses(now: now)
        let board = Board(
            status: statuses,
            id: UUID(),
            name: name,
            priority: boards.count,
            createdAt: now,
            updatedAt: now
        )

        do {
            try modelContext.transaction {
                statuses.forEach { modelContext.insert($0) }
                for status in statuses {
                    status.parentBoard = board
                }
                modelContext.insert(board)
            }
        } catch {
            print(error)
        }

        return board
    }

    private func initializeBoard() {
        let board = createNewBoard(name: String(localized: "Default"))
        selectBoard(board)
    }

    private func selectBoard(_ board: Board?) {
        selectedBoard = board
        selectedBoardID = board?.id.uuidString
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BooklogConst.modelTypes, inMemory: true)
}
