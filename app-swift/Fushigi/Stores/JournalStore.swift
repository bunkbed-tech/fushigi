//
//  JournalStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import Foundation
import SwiftData

// MARK: - Journal Store

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

    /// SwiftData database session for local persistence
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

    /// Load grammar points from local SwiftData storage
    func loadLocal() async {
        do {
            journalEntries = try modelContext.fetch(FetchDescriptor<JournalEntryLocal>())
            print("LOG: Loaded \(journalEntries.count) journal items from local storage")
        } catch {
            print("DEBUG: Failed to load local journal entries:", error)
            handleLocalLoadFailure()
        }
    }

    /// Sync journal entries from remote PostgreSQL database
    func syncWithRemote() async {
        setLoading()

        let result = await fetchJournalEntries()
        switch result {
        case let .success(remoteJournalEntries):
            await processRemoteJournalEntries(remoteJournalEntries)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("DEBUG: Failed to sync journal entries from PostgreSQL:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Process remote journal entries and update local storage
    private func processRemoteJournalEntries(_ remoteJournalEntries: [JournalEntryRemote]) async {
        for remote in remoteJournalEntries {
            // Check if exists locally by checking postgres id and swift id
            if let existing = journalEntries.first(where: { $0.id == remote.id }) {
                // Update existing
                existing.title = remote.title
                existing.content = remote.content
                existing.private = remote.private
                existing.createdAt = remote.createdAt
            } else {
                // Create new
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

        // Save to commit to permanent SwiftData storage
        do {
            try modelContext.save()
            print("LOG: Synced \(remoteJournalEntries.count) local journal entries with PostgreSQL.")
        } catch {
            print("DEBUG: Failed to save journal entries to local SwiftData:", error)
        }
    }

    /// Manual refresh for pull-to-refresh functionality
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

// MARK: - Preview Helpers

/// Preview and testing helpers
extension JournalStore {
    /// Set random grammar points for preview mode only
    func setJournalEntriesForPreview(_ items: [JournalEntryLocal]) {
        #if DEBUG
            journalEntries = items
        #endif
    }
}
