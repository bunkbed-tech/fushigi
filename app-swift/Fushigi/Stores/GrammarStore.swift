//
//  GrammarStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/14.
//

import Foundation
import SwiftData

// MARK: - Grammar Store

/// Observable store managing grammar points with local SwiftData storage and remote PostgreSQL sync
@MainActor
class GrammarStore: ObservableObject {
    /// In-memory cache of all grammar points for quick UI access
    @Published var grammarItems: [GrammarPointLocal] = []

    /// Daily subset of random grammar points for practice
    @Published private(set) var randomGrammarItems: [GrammarPointLocal] = []

    /// Daily subset of SRS-selected grammar points for practice
    @Published private(set) var algorithmicGrammarItems: [GrammarPointLocal] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, postgres error)
    @Published var systemHealth: SystemHealth = .healthy

    /// Last successful sync timestamp
    @Published var lastSyncDate: Date?

    /// Currently selected grammar item for quick UI
    @Published var selectedGrammarPoint: GrammarPointLocal?

    /// Last random subset update date
    private var lastRandomUpdate: Date?

    /// Last algorithmic subset update date
    private var lastAlgorithmicUpdate: Date?

    /// SwiftData database session for local persistence
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Helper Functions

    /// Get subset of 5 grammar points depending on what UI SourceMode is selected
    func getGrammarPoints(for: SourceMode) -> [GrammarPointLocal] {
        switch `for` {
        case .random:
            randomGrammarItems
        case .srs:
            algorithmicGrammarItems
        }
    }

    /// Filter grammar points by search text across usage, meaning, context, and tags
    func filterGrammarPoints(containing searchText: String? = nil) -> [GrammarPointLocal] {
        var filtered = grammarItems

        if let searchText, !searchText.isEmpty {
            filtered = filtered.filter {
                $0.usage.localizedCaseInsensitiveContains(searchText) ||
                    $0.meaning.localizedCaseInsensitiveContains(searchText) ||
                    $0.context.localizedCaseInsensitiveContains(searchText) ||
                    $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return filtered
    }

    /// Get specific grammar point by ID
    func getGrammarPoint(id: UUID?) -> GrammarPointLocal? {
        guard let id else { return nil } // protect id
        return grammarItems.first { $0.id == id }
    }

    /// Get specific random grammar point by ID
    func getRandomGrammarPoint(id: UUID?) -> GrammarPointLocal? {
        randomGrammarItems.first { $0.id == id }
    }

    /// Get specific SRS grammar point by ID
    func getAlgorithmicGrammarPoint(id: UUID?) -> GrammarPointLocal? {
        algorithmicGrammarItems.first { $0.id == id }
    }

    // MARK: - Sync Boilerplate

    /// Load grammar points from local SwiftData storage
    func loadLocal() async {
        do {
            grammarItems = try modelContext.fetch(FetchDescriptor<GrammarPointLocal>())
            print("LOG: Loaded \(grammarItems.count) grammar points from SwiftData")
        } catch {
            print("DEBUG: Failed to load local grammar points:", error)
            handleLocalLoadFailure()
        }
    }

    /// Sync grammar points from remote PostgreSQL database
    func syncWithRemote() async {
        setLoading()

        let result = await fetchGrammarPoints()
        switch result {
        case let .success(remotePoints):
            await processRemotePoints(remotePoints)
            lastSyncDate = Date()
            handleSyncSuccess()
        case let .failure(error):
            print("DEBUG: Failed to sync grammar points from PostgreSQL:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Process remote grammar points and update local storage
    private func processRemotePoints(_ remotePoints: [GrammarPointRemote]) async {
        for remote in remotePoints {
            // Check if exists locally by checking postgres id and swift id
            if let existing = grammarItems.first(where: { $0.id == remote.id }) {
                // Update existing
                existing.context = remote.context
                existing.usage = remote.usage
                existing.meaning = remote.meaning
                existing.tags = remote.tags
            } else {
                // Create new
                let newItem = GrammarPointLocal(
                    id: remote.id,
                    context: remote.context,
                    usage: remote.usage,
                    meaning: remote.meaning,
                    tags: remote.tags,
                )
                modelContext.insert(newItem)
                grammarItems.append(newItem)
            }
        }

        // Save to commit to permanent SwiftData storage
        do {
            try modelContext.save()
            print("LOG: Synced \(remotePoints.count) local grammar points with PostgreSQL.")
        } catch {
            print("DEBUG: Failed to save grammar points to local SwiftData:", error)
        }
    }

    /// Manual force refresh for all grammar data with sync
    func refresh() async {
        print("LOG: Refreshing data for GrammarStore...")
        await loadLocal()
        await syncWithRemote()
        updateRandomGrammarPoints(force: true)
        updateAlgorithmicGrammarPoints(force: true)
    }

    /// Manual force refresh of daily grammar only based on current mode without needing to sync
    func forceDailyRefresh(currentMode: SourceMode) {
        switch currentMode {
        case .random:
            updateRandomGrammarPoints(force: true)
        case .srs:
            updateAlgorithmicGrammarPoints(force: true)
        }
    }

    /// Update random grammar points subset with optional force refresh
    func updateRandomGrammarPoints(force: Bool = false) {
        // TODO: implement down filtering
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastRandomUpdate != today || randomGrammarItems.isEmpty {
            randomGrammarItems = Array(grammarItems.shuffled().prefix(5))
            lastRandomUpdate = today
            print("LOG: Picked \(randomGrammarItems.count) new random grammar items.")
        }
    }

    /// Update SRS-based grammar points subset with optional force refresh
    func updateAlgorithmicGrammarPoints(force: Bool = false) {
        // TODO: implement srs based grammar pulling with down filtering
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastAlgorithmicUpdate != today || algorithmicGrammarItems.isEmpty {
            algorithmicGrammarItems = Array(grammarItems.shuffled().prefix(5))
            lastAlgorithmicUpdate = today
            print("LOG: Picked \(algorithmicGrammarItems.count) new SRS grammar items.")
        }
    }
}

// Add on sync functionality
extension GrammarStore: SyncableStore {
    /// Main sync functionality is on GrammarPointLocal for this store
    typealias DataType = GrammarPointLocal
    var items: [GrammarPointLocal] { grammarItems }
}

// MARK: - Preview Helpers

/// Preview and testing helpers
extension GrammarStore {
    /// Set random grammar points for preview mode only
    func setRandomGrammarPointsForPreview(_ items: [GrammarPointLocal]) {
        #if DEBUG
            randomGrammarItems = items
        #endif
    }

    /// Set algorithmic grammar points for preview mode only
    func setAlgorithmicGrammarPointsForPreview(_ items: [GrammarPointLocal]) {
        #if DEBUG
            algorithmicGrammarItems = items
        #endif
    }
}
