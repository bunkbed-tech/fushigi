//
//  SystemHealth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

/// Represents the health of our data sources
enum SystemHealth {
    /// All systems operational
    case healthy

    /// Local SwiftData corruption/failure
    case swiftDataError

    /// Unable to establish connection to Pocketbase database
    case pocketbaseError

    /// User friendly description of data availability
    var description: String {
        switch self {
        case .healthy:
            "All systems operational"
        case .swiftDataError:
            "Local SwiftData corruption/failure"
        case .pocketbaseError:
            "Unable to establish connection to Pocketbase database"
        }
    }

    var hasError: Bool {
        self != .healthy
    }
}
