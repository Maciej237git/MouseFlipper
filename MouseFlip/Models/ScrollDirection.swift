import Foundation

enum ScrollDirection: String, Codable, CaseIterable {
    case standard
    case natural

    var displayName: String {
        switch self {
        case .standard:
            return "Normalny"
        case .natural:
            return "Naturalny"
        }
    }

    var statusLabel: String {
        switch self {
        case .standard:
            return "NORMALNY ↓"
        case .natural:
            return "NATURALNY"
        }
    }

    var preferenceBoolValue: Bool {
        self == .natural
    }

    init?(preferenceBoolValue: Bool) {
        self = preferenceBoolValue ? .natural : .standard
    }
}
