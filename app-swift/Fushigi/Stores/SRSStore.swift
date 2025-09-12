//
//  SRSStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/05.
//

import Foundation
import SwiftData

// MARK: - SRS Store

/// Manages srs algorithm values for grammar points with local SwiftData storage and remote PocketBase sync
@MainActor
class SRSStore: ObservableObject {
    // MARK: - Published State

    /// All SRS records available to the user
    @Published var srsRecords: [SRSRecordLocal] = []

    /// Daily random selection for practice (refreshes once per day)
    @Published private(set) var randomSRSRecords: [SRSRecordLocal] = []

    /// Daily SRS selection for practice (refreshes once per day)
    @Published private(set) var algorithmicSRSRecords: [SRSRecordLocal] = []

    /// Current data state (load, empty, normal)
    @Published var dataAvailability: DataAvailability = .empty

    /// Current system health (healthy, sync error, PocketBase error)
    @Published var systemHealth: SystemHealth = .healthy

    /// Last successful sync timestamp
    @Published var lastSyncDate: Date?

    /// Optimization set for checking if a grammar item has an SRS record associated with it
    @Published private(set) var grammarIDsInSRS: Set<String> = []

    // MARK: Private State

    /// Tracks when random subset was last updated
    private var lastRandomUpdate: Date?

    /// Tracks when SRS subset was last updated
    private var lastSRSUpdate: Date?

    // MARK: - Init

    let modelContext: ModelContext?
    let authManager: AuthManager
    let service: ProdRemoteService<SRSRecordRemote, SRSRecordCreate>

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        self.modelContext = modelContext
        self.authManager = authManager
        service = ProdRemoteService(endpoint: "srs", decoder: JSONDecoder.pocketBase)
    }

    // MARK: - Public API

    /// Returns true if grammar item has an active SRS record
    func isInSRS(_ grammar: String) -> Bool {
        grammarIDsInSRS.contains(grammar)
    }

    /// Single item add with unified return type
    func addToSRS(_ grammar: String) async {
        guard let user = authManager.currentUser?.id else { return }
        guard !isInSRS(grammar) else { return }

        setLoading()

        let newSRS = SRSRecordCreate(
            user: user,
            grammar: grammar,
            easeFactor: 2.5,
            intervalDays: 1.0,
            repetition: 1.0,
        )

        let result = await service.postItem(newSRS)

        switch result {
        case .success:
            handleSyncSuccess()
            await refresh()
        case let .failure(error):
            print("ERROR: Failed to post new SRS record for grammar points to PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Bulk operation with unified return type and duplicate filtering
    func addBulkToSRS(_ grammar: [GrammarPointLocal]) async {
        guard let user = authManager.currentUser?.id else { return }

        // Filter duplicates before API call
        let grammarToAdd = grammar.filter { !isInSRS($0.id) }
        guard !grammarToAdd.isEmpty else { return }

        setLoading()

        let bulkSRS = grammarToAdd.map { point in
            SRSRecordCreate(
                user: user,
                grammar: point.id,
                easeFactor: 2.5,
                intervalDays: 1.0,
                repetition: 1.0,
            )
        }

        let result = await service.postBulkItems(bulkSRS)

        switch result {
        case .success:
            handleSyncSuccess()
            await refresh()
        case let .failure(error):
            print("ERROR: Failed to post new SRS record for grammar points to PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Returns SRS records subset based on selected practice mode
    func getSRSRecords(for mode: SourceMode) -> [SRSRecordLocal] {
        switch mode {
        case .random:
            randomSRSRecords
        case .srs:
            algorithmicSRSRecords
        }
    }

    /// Finds SRS record by ID from current random selection
    func getRandomSRSRecord(id: String?) -> SRSRecordLocal? {
        guard let id else { return nil }
        return randomSRSRecords.first { $0.id == id }
    }

    /// Finds SRS record by ID from current SRS selection
    func getAlgorithmicSRSRecord(id: String?) -> SRSRecordLocal? {
        guard let id else { return nil }
        return algorithmicSRSRecords.first { $0.id == id }
    }

    /// Get SRS records due for review using database predicates
    func getRecordsDueForReview() -> [SRSRecordLocal] {
        guard let modelContext else {
            return srsRecords.filter { ($0.dueDate) <= Date() }
        }

        let now = Date()
        let descriptor = FetchDescriptor<SRSRecordLocal>(
            predicate: #Predicate<SRSRecordLocal> { record in
                (record.dueDate) <= now
            },
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Update a single SRS record with new values
    func updateSRSRecord(_ recordId: String, with update: SRSRecordUpdate) async {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<SRSRecordLocal>(
            predicate: #Predicate<SRSRecordLocal> { $0.id == recordId },
        )

        guard let record = try? modelContext.fetch(descriptor).first else { return }

        if let easeFactor = update.easeFactor { record.easeFactor = easeFactor }
        if let intervalDays = update.intervalDays { record.intervalDays = intervalDays }
        if let repetition = update.repetition { record.repetition = repetition }
        if let lastReviewed = update.lastReviewed { record.lastReviewed = lastReviewed }
        if let dueDate = update.dueDate { record.dueDate = dueDate }

        try? modelContext.save()
    }

    /// Updates random selection (once per day unless forced)
    func updateRandomSRSRecords(force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastRandomUpdate != today || randomSRSRecords.isEmpty {
            randomSRSRecords = Array(srsRecords.shuffled().prefix(min(5, srsRecords.count)))
            lastRandomUpdate = today
            print("LOG: Selected \(randomSRSRecords.count) random SRS records")
        }
    }

    /// Updates SRS selection (once per day unless forced)
    func updateAlgorithmicSRSRecords(force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        if force || lastSRSUpdate != today || algorithmicSRSRecords.isEmpty {
            // Use due records when available, otherwise random selection
            let dueRecords = getRecordsDueForReview()
            if !dueRecords.isEmpty {
                algorithmicSRSRecords = Array(dueRecords.prefix(min(5, dueRecords.count)))
            } else {
                algorithmicSRSRecords = Array(srsRecords.shuffled().prefix(min(5, srsRecords.count)))
            }
            lastSRSUpdate = today
            print("LOG: Selected \(algorithmicSRSRecords.count) SRS grammar items")
        }
    }

    /// Keep the list of grammar ids with SRS records up to date
    private func updateGrammarIDsSet() {
        grammarIDsInSRS = Set(srsRecords.map(\.grammar))
    }

    // MARK: - Sync Boilerplate

    /// Loads SRS records from local SwiftData
    func loadLocal() async {
        guard let modelContext else { return }
        do {
            srsRecords = try modelContext.fetch(FetchDescriptor<SRSRecordLocal>())
            updateGrammarIDsSet()
            print("LOG: Loaded \(srsRecords.count) SRS records from local storage")
        } catch {
            print("ERROR: Failed to load local SRS records:", error)
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
            print("ERROR: Failed to sync SRS records from PocketBase:", error)
            handleRemoteSyncFailure()
        }
    }

    /// Merges remote items using last-write-wins by updated timestamp
    private func mergeRemoteItems(_ remoteItems: [SRSRecordRemote]) async {
        guard let modelContext else { return }

        // Build index for O(1) lookups during merge
        var localIndex: [String: SRSRecordLocal] = [:]
        localIndex.reserveCapacity(srsRecords.count)
        for local in srsRecords {
            localIndex[local.id] = local
        }

        var newItems: [SRSRecordLocal] = []
        newItems.reserveCapacity(remoteItems.count)

        for remote in remoteItems {
            if let existing = localIndex[remote.id] {
                // Update existing if remote is newer
                if remote.updated > existing.updated {
                    existing.user = remote.user
                    existing.grammar = remote.grammar
                    existing.easeFactor = remote.easeFactor
                    existing.intervalDays = remote.intervalDays
                    existing.repetition = remote.repetition
                    existing.dueDate = remote.dueDate
                    existing.lastReviewed = remote.lastReviewed
                    existing.created = remote.created
                    existing.updated = remote.updated
                }
            } else {
                // Create new item with remote ID
                let newItem = SRSRecordLocal(
                    id: remote.id,
                    user: remote.user,
                    grammar: remote.grammar,
                    easeFactor: remote.easeFactor,
                    intervalDays: remote.intervalDays,
                    repetition: remote.repetition,
                    lastReviewed: remote.lastReviewed,
                    dueDate: remote.dueDate,
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
                srsRecords.append(contentsOf: newItems)
            }
            updateGrammarIDsSet()
            print("LOG: Synced \(remoteItems.count) SRS records. New: \(newItems.count)")
        } catch {
            print("ERROR: Failed to save SRS records to SwiftData:", error)
        }
    }

    /// Performs full data refresh with remote sync
    func refresh() async {
        print("LOG: Refreshing data for SRSStore...")
        await loadLocal()
        await syncWithRemote()
        updateRandomSRSRecords(force: true)
        updateAlgorithmicSRSRecords(force: true)
    }

    /// Clear all in memory data
    func clearInMemoryData() {
        srsRecords.removeAll()
        grammarIDsInSRS.removeAll()
        randomSRSRecords.removeAll()
        algorithmicSRSRecords.removeAll()
        dataAvailability = .empty
        systemHealth = .healthy
        lastSyncDate = nil
        lastRandomUpdate = nil
        lastSRSUpdate = nil
    }

    /// Forces refresh of daily practice selection without syncing
    func forceDailyRefresh(currentMode: SourceMode) {
        switch currentMode {
        case .random:
            updateRandomSRSRecords(force: true)
        case .srs:
            updateAlgorithmicSRSRecords(force: true)
        }
    }
}

// MARK: - SRS Record Update

struct SRSRecordUpdate {
    let easeFactor: Double?
    let intervalDays: Double?
    let repetition: Double?
    let lastReviewed: Date?
    let dueDate: Date?

    init(
        easeFactor: Double? = nil,
        intervalDays: Double? = nil,
        repetition: Double? = nil,
        lastReviewed: Date? = nil,
        dueDate: Date? = nil,
    ) {
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetition = repetition
        self.lastReviewed = lastReviewed
        self.dueDate = dueDate
    }
}

// MARK: - SyncableStore Conformance

extension SRSStore: SyncableStore {
    typealias DataType = SRSRecordLocal
    var items: [SRSRecordLocal] { srsRecords }
}

// MARK: - Preview Helpers

extension SRSStore {
    /// Sets random selection for preview/testing
    func setRandomSRSRecordsForPreview(_ items: [SRSRecordLocal]) {
        #if DEBUG
            randomSRSRecords = items
        #endif
    }

    /// Sets SRS selection for preview/testing
    func setAlgorithmicSRSRecordsForPreview(_ items: [SRSRecordLocal]) {
        #if DEBUG
            algorithmicSRSRecords = items
        #endif
    }
}
