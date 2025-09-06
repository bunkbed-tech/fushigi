//
//  SyncableStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftUI

// MARK: - Syncable Store Protocol

/// Protocol that any store with sync functionality can adopt
@MainActor
protocol SyncableStore: ObservableObject {
    associatedtype DataType

    var items: [DataType] { get }
    var dataAvailability: DataAvailability { get set }
    var systemHealth: SystemHealth { get set }
}

// MARK: - Syncable Store

/// Define shared attributes of all stores with sync
extension SyncableStore {
    /// Computed priority state for UI rendering decisions
    var systemState: SystemState {
        switch (dataAvailability, systemHealth) {
        case (.loading, _):
            .loading
        case (.empty, .healthy):
            .emptyData
        case (.empty, .swiftDataError), (.empty, .pocketbaseError):
            .criticalError(systemHealth.description)
        case (.available, .healthy):
            .normal
        case (.available, .swiftDataError), (.available, .pocketbaseError):
            .degradedOperation(systemHealth.description)
        }
    }

    /// Mark as loading
    func setLoading() {
        dataAvailability = .loading
    }

    /// Handle local load failure
    func handleLocalLoadFailure() {
        systemHealth = .swiftDataError
        dataAvailability = items.isEmpty ? .empty : .available
    }

    /// Handle remote sync failure
    func handleRemoteSyncFailure() {
        systemHealth = .pocketbaseError
        dataAvailability = items.isEmpty ? .empty : .available
    }

    /// Handle successful sync
    func handleSyncSuccess() {
        // Successful sync means PocketBase is working - clear postgres errors
        // But keep SwiftData errors since remote sync doesn't fix local storage
        if systemHealth == .pocketbaseError {
            systemHealth = .healthy
        }

        dataAvailability = items.isEmpty ? .empty : .available
    }
}
