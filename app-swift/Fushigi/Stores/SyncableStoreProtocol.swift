//
//  SyncableStoreProtocol.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftUI

// MARK: - Syncable Store Protocol

/// Protocol that any store with sync functionality can adopt
@MainActor
protocol SyncableStore: ObservableObject {
    // MARK: - Required Types

    /// Most important stored object type in this store
    associatedtype DataType

    /// Base list of most important object in this store
    var items: [DataType] { get }

    /// Overall data availability of this store
    var dataAvailability: DataAvailability { get set }

    /// Overall system health of this store
    var systemHealth: SystemHealth { get set }
}

// MARK: - Syncable Store

/// Define shared attributes of all stores with sync
extension SyncableStore {
    // MARK: - Shared Functionality

    /// Computed priority state for UI rendering decisions (special .emptySRS case determined in SRSStore.swift)
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
        // Successful sync means PocketBase is working - clear errors
        // Keep SwiftData errors since remote sync doesn't fix local storage
        if systemHealth == .pocketbaseError {
            systemHealth = .healthy
        }

        dataAvailability = items.isEmpty ? .empty : .available
    }
}
