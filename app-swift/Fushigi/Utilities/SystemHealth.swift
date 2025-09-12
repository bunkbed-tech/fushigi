//
//  SystemHealth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

// MARK: - System Health

/// Represents the health of our data sources
enum SystemHealth {
    /// All systems operational
    case healthy

    /// Local SwiftData corruption/failure
    case swiftDataError

    /// Unable to establish connection to PocketBase database
    case pocketbaseError

    /// User friendly description of data availability
    var description: String {
        switch self {
        case .healthy:
            "All systems operational"
        case .swiftDataError:
            "Local SwiftData corruption/failure"
        case .pocketbaseError:
            "Unable to establish connection to PocketBase database"
        }
    }

    /// Whether the following health state should be considered an error or not
    var hasError: Bool {
        self != .healthy
    }
}
