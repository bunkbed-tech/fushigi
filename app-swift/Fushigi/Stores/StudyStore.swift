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
    let sentenceStore: SentenceStore

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        grammarStore = GrammarStore(modelContext: modelContext, authManager: authManager)
        srsStore = SRSStore(modelContext: modelContext, authManager: authManager)
        sentenceStore = SentenceStore(modelContext: modelContext, authManager: authManager)
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

    /// User created sentences for a given grammar item
    var sentenceBank: [SentenceLocal] {
        sentenceStore.sentences.filter { $0.grammar == grammarStore.selectedGrammarPoint?.id}
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
