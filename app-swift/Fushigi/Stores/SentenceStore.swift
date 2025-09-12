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

    /// Temporary storage for sentence tags being created during journal composition
    @Published var pendingSentences: [SentenceCreate] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, PocketBase error)
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

    // MARK: - Public API

    /// Get sentences for a specific grammar point using database predicates
    func getSentencesForGrammar(_ grammarId: String) -> [SentenceLocal] {
        guard let modelContext else {
            return sentences.filter { $0.grammar == grammarId }
        }

        let descriptor = FetchDescriptor<SentenceLocal>(
            predicate: #Predicate<SentenceLocal> { $0.grammar == grammarId },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get sentences for a specific journal entry using database predicates
    func getSentencesForJournal(_ journalId: String) -> [SentenceLocal] {
        guard let modelContext else {
            return sentences.filter { $0.journalEntry == journalId }
        }

        let descriptor = FetchDescriptor<SentenceLocal>(
            predicate: #Predicate<SentenceLocal> { $0.journalEntry == journalId },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get sentences for a specific user using database predicates
    func getSentencesForUser(_ userId: String) -> [SentenceLocal] {
        guard let modelContext else {
            return sentences.filter { $0.user == userId }
        }

        let descriptor = FetchDescriptor<SentenceLocal>(
            predicate: #Predicate<SentenceLocal> { $0.user == userId },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get grammar usage statistics using efficient counting
    func getGrammarUsageStats() async -> [String: Int] {
        guard let modelContext else {
            // Fallback to in-memory counting
            var stats: [String: Int] = [:]
            for sentence in sentences {
                stats[sentence.grammar, default: 0] += 1
            }
            return stats
        }

        // Use database query for better performance
        let allSentences = (try? modelContext.fetch(FetchDescriptor<SentenceLocal>())) ?? []
        var stats: [String: Int] = [:]
        for sentence in allSentences {
            stats[sentence.grammar, default: 0] += 1
        }
        return stats
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
        sentences.removeAll()
        pendingSentences.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        lastSyncDate = nil
    }

    // MARK: - Pending Sentence Management

    /// Temporarily store a pending sentence while waiting for full Journal Entry to be submitted
    func addPendingTag(grammar: String, selectedText: String) async -> Result<String, Error> {
        guard let userID = authManager.currentUser?.id else {
            print("ERROR: No user ID in current session - auth failed")
            return .failure(URLError(.userAuthenticationRequired))
        }

        let tag = SentenceCreate(
            content: selectedText,
            user: userID,
            journalEntry: "TEMP",
            grammar: grammar,
        )

        pendingSentences.append(tag)
        print("LOG: Added pending sentence tag. Total: \(pendingSentences.count)")
        return .success("Added pending sentence tag.")
    }

    /// Remove tag according to the currently selected string
    func removePendingTag(content: String, grammar: String) {
        pendingSentences.removeAll(where: { $0.content == content && $0.grammar == grammar })
    }

    /// Bulk operation to send all pending sentences to the database
    func addPendingToDatabase(_ journal: String) async -> Result<Void, Error> {
        guard !pendingSentences.isEmpty else {
            print("LOG: No pending sentences to save")
            return .success(())
        }
        setLoading()

        let bulkSentence = pendingSentences.map { point in
            SentenceCreate(
                content: point.content,
                user: point.user,
                journalEntry: point.journalEntry == "TEMP" ? journal : point.journalEntry,
                grammar: point.grammar,
            )
        }

        let result = await service.postBulkItems(bulkSentence)

        switch result {
        case .success:
            print("LOG: Successfully saved \(pendingSentences.count) sentence tags")
            handleSyncSuccess()
            await refresh()
            pendingSentences.removeAll()
            return .success(())

        case let .failure(error):
            print("ERROR: Failed to post sentence tags for journal \(journal): \(error)")
            handleRemoteSyncFailure()
            return .failure(error)
        }
    }
}

// MARK: - SyncableStore Conformance

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
