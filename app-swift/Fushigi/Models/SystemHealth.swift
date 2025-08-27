//
//  SystemHealth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftUI

/// Represents the health of our data sources
enum SystemHealth {
    /// All systems operational
    case healthy

    /// Local SwiftData corruption/failure
    case swiftDataError

    /// Unable to establish connection to PostgreSQL database
    case postgresError

    /// User friendly description of data availability
    var description: String {
        switch self {
        case .healthy:
            "All systems operational"
        case .swiftDataError:
            "Local SwiftData corruption/failure"
        case .postgresError:
            "Unable to establish connection to PostgreSQL database"
        }
    }

    var hasError: Bool {
        self != .healthy
    }
}
