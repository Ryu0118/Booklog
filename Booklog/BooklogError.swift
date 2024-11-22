import Foundation

enum BooklogError: LocalizedError {
    case requestError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .requestError:
            String(localized: "An error occurred during the network request")
        case .unknownError:
            String(localized: "Unknown error")
        }
    }
}
