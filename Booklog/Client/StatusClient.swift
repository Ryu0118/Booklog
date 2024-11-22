import SwiftData
import Foundation

struct StatusClient {
    func fetchStatus(id: Status.ID, modelContext: ModelContext) throws -> Status {
        guard let status = try modelContext.fetch(
            FetchDescriptor<Status>(
                predicate: #Predicate {
                    $0.id == id
                }
            )
        ).first else {
            throw Error.statusNotFound
        }
        return status
    }

    enum Error: LocalizedError {
        case statusNotFound

        var errorDescription: String? {
            switch self {
            case .statusNotFound:
                String(localized: "Status cannot be found")
            }
        }
    }

}
