//
//  SentenceStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import Foundation
import SwiftData

// MARK: - Sentence Store

/// Manages "tagged sentences" with local SwiftData storage and remote PocketBase sync
@MainActor
class SentenceStore: ObservableObject {
    // MARK: - Published State

    /// In-memory cache of all sentence tags for quick UI access
    @Published var sentences: [SentenceLocal] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, postgres error)
    @Published var systemHealth: SystemHealth = .healthy

    /// Last successful sync timestamp
    @Published var lastSyncDate: Date?

    // MARK: - Init

    let modelContext: ModelContext?
    let authManager: AuthManager
    let service: ProdRemoteService<SentenceRemote, SentenceCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "sentence", decoder: JSONDecoder.pocketBase)
    }

    // MARK: - Sync Boilerplate

    /// Loads sentence tags from local SwiftData
    func loadLocal() async {
        guard let modelContext else { return }
        do {
            sentences = try modelContext.fetch(FetchDescriptor<SentenceLocal>())
            print("LOG: Loaded \(sentences.count) sentence tags from local storage")
        } catch {
            print("ERROR: Failed to load local sentence tags:", error)
            handleLocalLoadFailure()
        }
    }

    /// Syncs sentence tags from remote PocketBase
    func syncWithRemote() async {
        setLoading()

        let result = await service.fetchAllItems()
        switch result {
        case let .success(remoteItems):
            await mergeRemoteItems(remoteItems)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("ERROR: Failed to sync sentence tags from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Merges remote items using last-write-wins by updated timestamp
    private func mergeRemoteItems(_ remoteItems: [SentenceRemote]) async {
        guard let modelContext else { return }

        // Build index for O(1) lookups during merge
        var localIndex: [String: SentenceLocal] = [:]
        localIndex.reserveCapacity(sentences.count)
        for local in sentences {
            localIndex[local.id] = local
        }

        var newItems: [SentenceLocal] = []
        newItems.reserveCapacity(remoteItems.count)

        for remote in remoteItems {
            if let existing = localIndex[remote.id] {
                // Update existing if remote is newer
                if remote.updated > existing.updated {
                    existing.user = remote.user
                    existing.journalEntry = remote.journalEntry
                    existing.grammar = remote.grammar
                    existing.content = remote.content
                    existing.created = remote.created
                    existing.updated = remote.updated
                }
            } else {
                // Create new item with remote ID
                let newItem = SentenceLocal(
                    id: remote.id,
                    user: remote.user,
                    journalEntry: remote.journalEntry,
                    grammar: remote.grammar,
                    content: remote.content,
                    created: remote.created,
                    updated: remote.updated,
                )
                modelContext.insert(newItem)
                newItems.append(newItem)
            }
        }

        // Persist changes and update in-memory state
        do {
            try modelContext.save()
            if !newItems.isEmpty {
                sentences.append(contentsOf: newItems)
            }
            print("LOG: Synced \(remoteItems.count) sentence tags. New: \(newItems.count)")
        } catch {
            print("ERROR: Failed to save sentence tags to SwiftData:", error)
        }
    }

    /// Performs full data refresh with remote sync
    func refresh() async {
        print("LOG: Refreshing data for SentenceStore...")
        await loadLocal()
        await syncWithRemote()
    }

    /// Clear all in memory data
    func clearInMemoryData() {
        // Clear in-memory data (everything Published)
        sentences.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        lastSyncDate = nil
    }
}

// MARK: - SyncableStore Conformance

// Add on sync functionality
extension SentenceStore: SyncableStore {
    typealias DataType = SentenceLocal
    var items: [SentenceLocal] { sentences }
}

/// Preview and testing helpers
extension SentenceStore {
    /// Set random grammar points for preview mode only
    func setSentencesForPreview(_ items: [SentenceLocal]) {
        #if DEBUG
            sentences = items
        #endif
    }
}
