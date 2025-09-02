//
//  SentenceStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import Foundation
import SwiftData

@MainActor
class SentenceStore: ObservableObject {
    @Published var sentences: [SentenceLocal] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, postgres error)
    @Published var systemHealth: SystemHealth = .healthy

    /// Last successful sync timestamp
    @Published var lastSyncDate: Date?

    let modelContext: ModelContext?

    let authManager: AuthManager

    let service: ProdRemoteService<SentenceRemote, SentenceCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        self.service = ProdRemoteService(endpoint: "sentences", decoder: JSONDecoder.iso8601withFractionalSeconds)
    }

    // MARK: - Sync Boilerplate

    func loadLocal() async {
        guard let modelContext else { return }
        do {
            sentences = try modelContext.fetch(FetchDescriptor<SentenceLocal>())
            print("LOG: Loaded \(sentences.count) sentence tags from local storage")
        } catch {
            print("DEBUG: Failed to load local sentence tags:", error)
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
        case let .failure(error):
            print("DEBUG: Failed to sync sentence tags from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    private func processRemoteItems(_ remoteItems: [SentenceRemote]) async {
        guard let modelContext else { return }
        for remote in remoteItems {
            if let existing = sentences.first(where: { $0.id == remote.id }) {
                existing.journalEntryId = remote.journalEntryId
                existing.grammarId = remote.grammarId
                existing.content = remote.content
                existing.createdAt = remote.createdAt
            } else {
                let newItem = SentenceLocal(
                    id: remote.id,
                    journalEntryId: remote.journalEntryId,
                    grammarId: remote.grammarId,
                    content: remote.content,
                    createdAt: remote.createdAt,
                )
                modelContext.insert(newItem)
                sentences.append(newItem)
            }
        }

        do {
            try modelContext.save()
            print("LOG: Synced \(remoteItems.count) local sentence tags with PocketBase.")
            handleSyncSuccess()
        } catch {
            print("DEBUG: Failed to save sentence tags to local SwiftData:", error)
        }
    }

    func refresh() async {
        print("LOG: Refreshing data for SentenceStore...")
        await loadLocal()
        await syncWithRemote()
    }
}

// Add on sync functionality
extension SentenceStore: SyncableStore {
    /// Main sync functionality is on SentenceLocal for this store
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
