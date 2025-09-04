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

    /// Journal entries marked as private
    var privateJournalEntries: [JournalEntryLocal] {
        journalEntries.filter(\.isPrivate)
    }

    /// Journal entries marked as public
    var publicJournalEntries: [JournalEntryLocal] {
        journalEntries.filter { !$0.isPrivate }
    }

    let modelContext: ModelContext?

    let authManager: AuthManager

    let service: ProdRemoteService<JournalEntryRemote, JournalEntryCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "journal_entry", decoder: JSONDecoder.pocketBase)
    }

    /// Returns journal entries filtered by search text and sorted by the specified key
    func getJournalEntries(
        for items: [JournalEntryLocal],
        sortedBy sortKey: JournalSort,
        containing term: String? = nil,
    ) -> [JournalEntryLocal] {
        var result = items

        // Apply filtering if search term exists
        if let term, !term.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(term) ||
                    $0.content.localizedCaseInsensitiveContains(term)
            }
        }

        // Always apply sorting
        return result.sorted { lhs, rhs in
            switch sortKey {
            case .title:
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            case .newest:
                lhs.created > rhs.created
            case .oldest:
                lhs.created < rhs.created
            }
        }
    }

    /// Create a Journal Entry as the current user using JournalEntryForm view
    func createEntry(title: String, content: String, isPrivate: Bool) async -> Result<String, Error> {
        print("LOG: Create entry called: \(title)")

        guard let userID = authManager.currentUser?.id else {
            print("ERROR: No user ID in current session - auth failed")
            return .failure(URLError(.userAuthenticationRequired))
        }

        let newItem = JournalEntryCreate(
            title: title,
            content: content,
            isPrivate: isPrivate,
            user: userID,
        )

        let result = await service.postItem(newItem)

        if case .success = result {
            // Refresh local data with the remote to include the new entry
            await syncWithRemote()
        } else {
            print("TODO: Need to save this locally and deal with sync forward later.")
        }

        return result
    }

    // MARK: - Sync Boilerplate

    func loadLocal() async {
        guard let modelContext else { return }
        do {
            journalEntries = try modelContext.fetch(FetchDescriptor<JournalEntryLocal>())
            print("LOG: Loaded \(journalEntries.count) journal items from local storage")
        } catch {
            print("ERROR: Failed to load local journal entries:", error)
            handleLocalLoadFailure()
        }
    }

    func syncWithRemote() async {
        setLoading()

        let result = await service.fetchAllItems()
        switch result {
        case let .success(remoteItems):
            await processRemoteItems(remoteItems)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("ERROR: Failed to sync journal entries from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    private func processRemoteItems(_ remoteItems: [JournalEntryRemote]) async {
        guard let modelContext else { return }
        for remote in remoteItems {
            if let existing = journalEntries.first(where: { $0.id == remote.id }) {
                existing.user = remote.user
                existing.title = remote.title
                existing.content = remote.content
                existing.isPrivate = remote.isPrivate
                existing.created = remote.created
                existing.updated = remote.updated
            } else {
                let newItem = JournalEntryLocal(
                    id: remote.id,
                    user: remote.user,
                    title: remote.title,
                    content: remote.content,
                    isPrivate: remote.isPrivate,
                    created: remote.created,
                    updated: remote.updated,
                )
                modelContext.insert(newItem)
                journalEntries.append(newItem)
            }
        }

        do {
            try modelContext.save()
            print("LOG: Synced \(remoteItems.count) local journal entries with PocketBase.")
        } catch {
            print("ERROR: Failed to save journal entries to local SwiftData:", error)
        }
    }

    func refresh() async {
        print("LOG: Refreshing data for JournalStore...")
        await loadLocal()
        await syncWithRemote()
    }

    /// Clear all in memory data
    func clearInMemoryData() {
        // Clear in-memory data (everything Published)
        journalEntries.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        lastSyncDate = nil
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
