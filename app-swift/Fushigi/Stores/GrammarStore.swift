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

    /// Daily random selection for practice (refreshes once per day)
    @Published private(set) var randomGrammarItems: [GrammarPointLocal] = []

    /// Daily SRS selection for practice (refreshes once per day)
    @Published private(set) var srsGrammarItems: [GrammarPointLocal] = []

    /// Current data loading state
    @Published var dataAvailability: DataAvailability = .empty

    /// Current sync health status
    @Published var systemHealth: SystemHealth = .healthy

    /// Timestamp of last successful remote sync
    @Published var lastSyncDate: Date?

    /// Currently selected item (set by UI, not managed by store)
    @Published var selectedGrammarPoint: GrammarPointLocal?

    // MARK: Private State

    /// Tracks when random subset was last updated
    private var lastRandomUpdate: Date?

    /// Tracks when SRS subset was last updated
    private var lastSRSUpdate: Date?

    // MARK: Computed Properties

    /// Grammar points created by system/admin (no user ownership)
    var systemGrammarItems: [GrammarPointLocal] {
        grammarItems.filter { $0.user?.isEmpty ?? true }
    }

    /// Grammar points created by current user
    var userGrammarItems: [GrammarPointLocal] {
        grammarItems.filter { !($0.user?.isEmpty ?? true) }
    }

    // MARK: Dependencies

    let modelContext: ModelContext?
    let authManager: AuthManager
    let service: ProdRemoteService<GrammarPointRemote, GrammarPointCreate>

    // MARK: Init

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "grammar", decoder: JSONDecoder.pocketBase)
    }

    // MARK: - Public API

    /// Returns grammar subset based on selected practice mode
    func getGrammarPoints(for mode: SourceMode) -> [GrammarPointLocal] {
        switch mode {
        case .random:
            randomGrammarItems
        case .srs:
            srsGrammarItems
        }
    }

    /// Filters grammar points by search term across all text fields
    func filterGrammarPoints(for items: [GrammarPointLocal], containing term: String? = nil) -> [GrammarPointLocal] {
        guard let term, !term.isEmpty else { return items }
        return items.filter {
            $0.usage.localizedCaseInsensitiveContains(term) ||
                $0.meaning.localizedCaseInsensitiveContains(term) ||
                $0.context.localizedCaseInsensitiveContains(term) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    /// Finds grammar point by ID from all available items
    func getGrammarPoint(id: String?) -> GrammarPointLocal? {
        guard let id else { return nil }
        return grammarItems.first { $0.id == id }
    }

    /// Finds grammar point by ID from current random selection
    func getRandomGrammarPoint(id: String?) -> GrammarPointLocal? {
        guard let id else { return nil }
        return randomGrammarItems.first { $0.id == id }
    }

    /// Finds grammar point by ID from current SRS selection
    func getSRSGrammarPoint(id: String?) -> GrammarPointLocal? {
        guard let id else { return nil }
        return srsGrammarItems.first { $0.id == id }
    }

    /// Forces refresh of daily practice selection without syncing
    func forceDailyRefresh(currentMode: SourceMode) {
        switch currentMode {
        case .random:
            updateRandomGrammarPoints(force: true)
        case .srs:
            updateSRSGrammarPoints(force: true)
        }
    }

    /// Updates random selection (once per day unless forced)
    func updateRandomGrammarPoints(force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastRandomUpdate != today || randomGrammarItems.isEmpty {
            randomGrammarItems = Array(grammarItems.shuffled().prefix(5))
            lastRandomUpdate = today
            print("LOG: Selected \(randomGrammarItems.count) random grammar items")
        }
    }

    /// Updates SRS selection (once per day unless forced)
    /// Currently uses random selection until SRS algorithm is implemented
    func updateSRSGrammarPoints(force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastSRSUpdate != today || srsGrammarItems.isEmpty {
            srsGrammarItems = Array(grammarItems.shuffled().prefix(5))
            lastSRSUpdate = today
            print("LOG: Selected \(srsGrammarItems.count) SRS grammar items")
        }
    }

    // MARK: - Sync

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

    /// Performs full data refresh with remote sync
    func refresh() async {
        print("LOG: Refreshing data for GrammarStore...")
        await loadLocal()
        await syncWithRemote()
        updateRandomGrammarPoints(force: true)
        updateSRSGrammarPoints(force: true)
    }

    /// Clears all in-memory data (preserves local storage)
    func clearInMemoryData() {
        grammarItems.removeAll()
        randomGrammarItems.removeAll()
        srsGrammarItems.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        selectedGrammarPoint = nil
        lastSyncDate = nil
        lastRandomUpdate = nil
        lastSRSUpdate = nil
    }

    // MARK: - Internal Sync

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
}

// MARK: - SyncableStore

extension GrammarStore: SyncableStore {
    typealias DataType = GrammarPointLocal
    var items: [GrammarPointLocal] { grammarItems }
}

// MARK: - Preview Helpers

extension GrammarStore {
    /// Sets random selection for preview/testing
    func setRandomGrammarPointsForPreview(_ items: [GrammarPointLocal]) {
        #if DEBUG
            randomGrammarItems = items
        #endif
    }

    /// Sets SRS selection for preview/testing
    func setSRSGrammarPointsForPreview(_ items: [GrammarPointLocal]) {
        #if DEBUG
            srsGrammarItems = items
        #endif
    }
}
