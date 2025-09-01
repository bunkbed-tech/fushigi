//
//  DataAvailability.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftUI

/// Represents whether the app has usable data for the user
enum DataAvailability {
    /// Loading data...
    case loading

    /// Data ready
    case available

    /// No data available
    case empty

    /// User friendly description of data availability
    var description: String {
        switch self {
        case .loading:
            "Loading data..."
        case .available:
            "Data ready"
        case .empty:
            "No data available"
        }
    }
}
