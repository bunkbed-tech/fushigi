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

    /// SwiftData database session for local persistence
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

//    func linkGrammar(_ grammarID: UUID, to journalID: UUID){
//        // TODO
//    }
//
//    func removeLink(sentenceID: UUID) {
//        // TODO
//    }
//
//    func getLinkedGrammar(for journalID: UUID) -> [SentenceLocal] {
//        // TODO
//    }
//
//    func getLinkedJournals(for grammarID: UUID) -> [SentenceLocal] {
//        // TODO
//    }

    // MARK: - Internal sync logic

    /// Load sentence tags from local SwiftData storage
    func loadLocal() async {
        do {
            sentences = try modelContext.fetch(FetchDescriptor<SentenceLocal>())
            print("LOG: Loaded \(sentences.count) sentence tags from local storage")
        } catch {
            print("DEBUG: Failed to load local sentence tags:", error)
            handleLocalLoadFailure()
        }
    }

    /// Sync sentences from remote PostgreSQL database
    func syncWithRemote() async {
        setLoading()

        let result = await fetchSentences()
        switch result {
        case let .success(remoteSentences):
            await processRemoteSentences(remoteSentences)
            lastSyncDate = Date()
        case let .failure(error):
            print("DEBUG: Failed to sync sentence tags from PostgreSQL:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Process remote sentences and update local storage
    private func processRemoteSentences(_ remoteSentences: [SentenceRemote]) async {
        for remote in remoteSentences {
            // Check if exists locally by checking postgres id and swift id
            if let existing = sentences.first(where: { $0.id == remote.id }) {
                // Update existing
                existing.journalEntryId = remote.journalEntryId
                existing.grammarId = remote.grammarId
                existing.content = remote.content
                existing.createdAt = remote.createdAt
            } else {
                // Create new
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

        // Save to commit to permanent SwiftData storage
        do {
            try modelContext.save()
            print("LOG: Synced \(remoteSentences.count) local sentence tags with PostgreSQL.")
            handleSyncSuccess()
        } catch {
            print("DEBUG: Failed to save sentence tags to local SwiftData:", error)
        }
    }

    /// Manual refresh for pull-to-refresh functionality
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

// MARK: - Preview Helpers

/// Preview and testing helpers
extension SentenceStore {
    /// Set random grammar points for preview mode only
    func setSentencesForPreview(_ items: [SentenceLocal]) {
        #if DEBUG
            sentences = items
        #endif
    }
}
