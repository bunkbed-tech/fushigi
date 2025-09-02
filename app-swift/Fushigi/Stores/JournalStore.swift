//
//  JournalStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import Foundation
import SwiftData

/// Observable store managing journal entries with local SwiftData storage and remote PostgreSQL sync
@MainActor
class JournalStore: ObservableObject {
    /// In-memory cache of all journal entries for quick UI access
    @Published var journalEntries: [JournalEntryLocal] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, postgres error)
    @Published var systemHealth: SystemHealth = .healthy

    /// Last successful sync timestamp
    @Published var lastSyncDate: Date?

    let modelContext: ModelContext?

    let authManager: AuthManager

    let service: ProdRemoteService<JournalEntryRemote, JournalEntryCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "journal", decoder: JSONDecoder.iso8601withFractionalSeconds)
    }

    /// Filter grammar points by search text across usage, meaning, context, and tags
    func filterJournalEntries(containing searchText: String? = nil) -> [JournalEntryLocal] {
        var filtered = journalEntries

        if let searchText, !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                    $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    // MARK: - Sync Boilerplate

    func loadLocal() async {
        guard let modelContext else { return }
        do {
            journalEntries = try modelContext.fetch(FetchDescriptor<JournalEntryLocal>())
            print("LOG: Loaded \(journalEntries.count) journal items from local storage")
        } catch {
            print("DEBUG: Failed to load local journal entries:", error)
            handleLocalLoadFailure()
        }
    }

    func syncWithRemote() async {
        setLoading()

        let result = await service.fetchItems()
        switch result {
        case let .success(remoteItems):
            await processRemoteItems(remoteItems)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("DEBUG: Failed to sync journal entries from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    private func processRemoteItems(_ remoteItems: [JournalEntryRemote]) async {
        guard let modelContext else { return }
        for remote in remoteItems {
            if let existing = journalEntries.first(where: { $0.id == remote.id }) {
                existing.title = remote.title
                existing.content = remote.content
                existing.private = remote.private
                existing.createdAt = remote.createdAt
            } else {
                let newItem = JournalEntryLocal(
                    id: remote.id,
                    title: remote.title,
                    content: remote.content,
                    private: remote.private,
                    createdAt: remote.createdAt,
                )
                modelContext.insert(newItem)
                journalEntries.append(newItem)
            }
        }

        do {
            try modelContext.save()
            print("LOG: Synced \(remoteItems.count) local journal entries with PocketBase.")
        } catch {
            print("DEBUG: Failed to save journal entries to local SwiftData:", error)
        }
    }

    func refresh() async {
        print("LOG: Refreshing data for JournalStore...")
        await loadLocal()
        await syncWithRemote()
    }
}

// Add on sync functionality
extension JournalStore: SyncableStore {
    /// Main sync functionality is on JournalEntryLocal for this store
    typealias DataType = JournalEntryLocal
    var items: [JournalEntryLocal] { journalEntries }
}

/// Preview and testing helpers
extension JournalStore {
    /// Set random grammar points for preview mode only
    func setJournalEntriesForPreview(_ items: [JournalEntryLocal]) {
        #if DEBUG
            journalEntries = items
        #endif
    }
}
