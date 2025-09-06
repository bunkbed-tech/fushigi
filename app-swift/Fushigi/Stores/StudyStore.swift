//
//  StudyStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/05.
//

import Foundation
import SwiftData

// MARK: - Study Store

// Wrapper around GrammarStore and SRSStore since they are tightly coupled
@MainActor
class StudyStore: ObservableObject {
    // MARK: - Init

    let grammarStore: GrammarStore
    let srsStore: SRSStore

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        grammarStore = GrammarStore(modelContext: modelContext, authManager: authManager)
        srsStore = SRSStore(modelContext: modelContext, authManager: authManager)
    }

    // MARK: - Cross-store Computed Properties

    /// Grammar points that have active SRS records
    var inSRSGrammarItems: [GrammarPointLocal] {
        grammarStore.grammarItems.filter { srsStore.isInSRS($0.id) }
    }

    /// Grammar points available to add to SRS (not yet added)
    var availableGrammarItems: [GrammarPointLocal] {
        grammarStore.grammarItems.filter { !srsStore.isInSRS($0.id) }
    }

    /// System state when views depend on both SRS and grammar
    var systemState: SystemState {
        let grammarState = grammarStore.systemState
        let srsState = srsStore.systemState

        // Grammar issues are always critical
        if case .criticalError = grammarState {
            return grammarState
        }
        if case .emptyData = grammarState {
            return grammarState
        }
        if case .loading = grammarState {
            return grammarState
        }

        // Grammar is healthy, check SRS states explicitly
        if case .criticalError = srsState {
            return srsState
        }
        if case .loading = srsState {
            return srsState
        }
        if case .emptySRS = srsState {
            return srsState
        }

        // Handle degraded states
        if case .degradedOperation = grammarState {
            return grammarState
        }
        if case .degradedOperation = srsState {
            return srsState
        }

        // Both stores are normal
        return .normal
    }

    // MARK: - Public API

    /// Adds a grammar point to the user's SRS system
    func addGrammarToSRS(_ grammar: GrammarPointLocal) async -> Result<String, Error> {
        print("LOG: Adding grammar point to SRS")
        return await srsStore.addToSRS(grammar: grammar.id)
    }

    // MARK: - Sync Boilerplate

    /// Performs full data refresh with remote sync
    func refresh() async {
        await grammarStore.refresh()
        await srsStore.refresh()
    }

    /// Clear all in memory data
    func clearInMemoryData() {
        grammarStore.clearInMemoryData()
        srsStore.clearInMemoryData()
    }
}
