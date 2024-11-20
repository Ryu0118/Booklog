import Foundation

enum BooklogError: LocalizedError {
    case requestError

    var errorDescription: String? {
        switch self {
        case .requestError:
            String(localized: "An error occurred during the network request")
        }
    }
}
