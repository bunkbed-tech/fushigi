//
//  GrammarStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/14.
//

import Foundation
import SwiftData

// MARK: - Grammar Store

/// Manages grammar points with local SwiftData storage and remote PocketBase sync
@MainActor
class GrammarStore: ObservableObject {
    // MARK: Published State

    /// All grammar points available to the user
    @Published var grammarItems: [GrammarPointLocal] = []

    /// Current data loading state
    @Published var dataAvailability: DataAvailability = .empty

    /// Current sync health status
    @Published var systemHealth: SystemHealth = .healthy

    /// Timestamp of last successful remote sync
    @Published var lastSyncDate: Date?

    /// Currently selected item (set by UI, not managed by store)
    @Published var selectedGrammarPoint: GrammarPointLocal?

    // MARK: Computed Properties

    /// Grammar points created by system/admin (no user ownership)
    var systemGrammarItems: [GrammarPointLocal] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<GrammarPointLocal>(
            predicate: #Predicate { $0.user == nil },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Grammar points created by current user
    var userGrammarItems: [GrammarPointLocal] {
        guard let modelContext else { return [] }
        guard let userId = authManager.currentUser?.id else { return [] }
        let descriptor = FetchDescriptor<GrammarPointLocal>(
            predicate: #Predicate<GrammarPointLocal> { grammar in
                grammar.user == userId
            },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: Init

    let modelContext: ModelContext?
    let authManager: AuthManager
    let service: ProdRemoteService<GrammarPointRemote, GrammarPointCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "grammar", decoder: JSONDecoder.pocketBase)
    }

    // MARK: - Public API

    /// Returns true if grammar item is a default (system-provided) by id
    func isDefaultGrammar(_ grammar: GrammarPointLocal) -> Bool {
        grammar.user == nil
    }

    /// Finds grammar point by ID from all available items
    func getGrammarPoint(id: String?) -> GrammarPointLocal? {
        guard let id, let modelContext else { return nil }
        let descriptor = FetchDescriptor<GrammarPointLocal>(
            predicate: #Predicate<GrammarPointLocal> { $0.id == id },
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Filters grammar points by search term across all text fields
    func filterGrammarPoints(
        for baseItems: [GrammarPointLocal],
        containing searchText: String? = nil,
    ) -> [GrammarPointLocal] {
        guard let searchText, !searchText.isEmpty else { return baseItems }

        if let modelContext {
            let descriptor = FetchDescriptor<GrammarPointLocal>(
                predicate: #Predicate<GrammarPointLocal> { grammar in
                    grammar.usage.localizedStandardContains(searchText) ||
                        grammar.meaning.localizedStandardContains(searchText) ||
                        grammar.context.localizedStandardContains(searchText)
                },
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        }

        // Fallback to in-memory filtering
        return baseItems.filter {
            $0.usage.localizedCaseInsensitiveContains(searchText) ||
                $0.meaning.localizedCaseInsensitiveContains(searchText) ||
                $0.context.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// Database-level search filtering using SwiftData predicates
    func searchGrammarPoints(_ searchText: String) async -> [GrammarPointLocal] {
        guard let modelContext, !searchText.isEmpty else { return [] }

        let descriptor = FetchDescriptor<GrammarPointLocal>(
            predicate: #Predicate<GrammarPointLocal> { grammar in
                grammar.usage.localizedStandardContains(searchText) ||
                    grammar.meaning.localizedStandardContains(searchText) ||
                    grammar.context.localizedStandardContains(searchText)
            },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Basic grammar usage analytics
    func getGrammarUsageAnalytics() async -> GrammarAnalytics {
        GrammarAnalytics(
            totalPoints: grammarItems.count,
            systemPoints: systemGrammarItems.count,
            userPoints: userGrammarItems.count,
        )
    }

    // MARK: - Sync Boilerplate

    /// Loads grammar points from local SwiftData
    func loadLocal() async {
        guard let modelContext else { return }
        do {
            let fetched = try modelContext.fetch(FetchDescriptor<GrammarPointLocal>())
            grammarItems = fetched
            print("LOG: Loaded \(grammarItems.count) grammar points from SwiftData")
            dataAvailability = grammarItems.isEmpty ? .empty : .available
        } catch {
            print("ERROR: Failed to load local grammar points:", error)
            handleLocalLoadFailure()
        }
    }

    /// Syncs grammar points from remote PocketBase
    func syncWithRemote() async {
        setLoading()

        let result = await service.fetchAllItems()
        switch result {
        case let .success(remoteItems):
            await mergeRemoteItems(remoteItems)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("ERROR: Failed to sync grammar points from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Merges remote items using last-write-wins by updated timestamp
    private func mergeRemoteItems(_ remoteItems: [GrammarPointRemote]) async {
        guard let modelContext else { return }

        // Build index for O(1) lookups during merge
        var localIndex: [String: GrammarPointLocal] = [:]
        localIndex.reserveCapacity(grammarItems.count)
        for local in grammarItems {
            localIndex[local.id] = local
        }

        var newItems: [GrammarPointLocal] = []
        newItems.reserveCapacity(remoteItems.count)

        for remote in remoteItems {
            if let existing = localIndex[remote.id] {
                // Update existing if remote is newer
                if remote.updated > existing.updated {
                    existing.user = remote.user.isEmpty ? nil : remote.user
                    existing.language = remote.language
                    existing.context = remote.context
                    existing.usage = remote.usage
                    existing.meaning = remote.meaning
                    existing.tags = remote.tags
                    existing.notes = remote.notes
                    existing.nuance = remote.nuance
                    existing.examples = remote.examples
                    existing.created = remote.created
                    existing.updated = remote.updated
                }
            } else {
                // Create new item with remote ID
                let newItem = GrammarPointLocal(
                    id: remote.id,
                    user: remote.user.isEmpty ? nil : remote.user,
                    language: remote.language,
                    context: remote.context,
                    usage: remote.usage,
                    meaning: remote.meaning,
                    tags: remote.tags,
                    notes: remote.notes,
                    nuance: remote.nuance,
                    examples: remote.examples,
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
                grammarItems.append(contentsOf: newItems)
            }
            print("LOG: Synced \(remoteItems.count) grammar points. New: \(newItems.count)")
        } catch {
            print("ERROR: Failed to save grammar points to SwiftData:", error)
        }
    }

    /// Performs full data refresh with remote sync
    func refresh() async {
        print("LOG: Refreshing data for GrammarStore...")
        await loadLocal()
        await syncWithRemote()
    }

    /// Clears all in-memory data (preserves local storage)
    func clearInMemoryData() {
        grammarItems.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        selectedGrammarPoint = nil
        lastSyncDate = nil
    }
}

// MARK: - SyncableStore Conformance

/// Add on sync functionality
extension GrammarStore: SyncableStore {
    typealias DataType = GrammarPointLocal
    var items: [GrammarPointLocal] { grammarItems }
}

// MARK: - Grammar Analytics

/// Analytics data structure
struct GrammarAnalytics {
    let totalPoints: Int
    let systemPoints: Int
    let userPoints: Int
}
