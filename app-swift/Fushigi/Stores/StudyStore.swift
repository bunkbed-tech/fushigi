//
//  StudyStore.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/05.
//

import Foundation
import SwiftData

// MARK: - Study Store

/// Wrapper around GrammarStore and SRSStore since they are tightly coupled
@MainActor
class StudyStore: ObservableObject {
    // MARK: - Init

    let grammarStore: GrammarStore
    let srsStore: SRSStore
    let sentenceStore: SentenceStore
    let journalStore: JournalStore

    init(
        modelContext: ModelContext,
        authManager: AuthManager,
    ) {
        grammarStore = GrammarStore(modelContext: modelContext, authManager: authManager)
        srsStore = SRSStore(modelContext: modelContext, authManager: authManager)
        sentenceStore = SentenceStore(modelContext: modelContext, authManager: authManager)
        journalStore = JournalStore(modelContext: modelContext, authManager: authManager)
    }

    // MARK: - Cross-store Computed Properties

    /// Grammar points that have active SRS records - optimized with database filtering
    var inSRSGrammarItems: [GrammarPointLocal] {
        guard grammarStore.modelContext != nil else {
            return grammarStore.grammarItems.filter { srsStore.isInSRS($0.id) }
        }

        let srsGrammarIds = srsStore.grammarIDsInSRS
        guard !srsGrammarIds.isEmpty else { return [] }

        // Use database predicate when possible - fallback to in-memory for complex Set contains
        return grammarStore.grammarItems.filter { srsGrammarIds.contains($0.id) }
    }

    /// Grammar points available to add to SRS (not yet added) - optimized with database filtering
    var availableGrammarItems: [GrammarPointLocal] {
        guard grammarStore.modelContext != nil else {
            return grammarStore.grammarItems.filter { !srsStore.isInSRS($0.id) }
        }

        let srsGrammarIds = srsStore.grammarIDsInSRS
        return grammarStore.grammarItems.filter { !srsGrammarIds.contains($0.id) }
    }

    /// User created sentences for a given grammar item - uses database predicates
    var sentenceBank: [SentenceLocal] {
        guard let selectedId = grammarStore.selectedGrammarPoint?.id else { return [] }
        return sentenceStore.getSentencesForGrammar(selectedId)
    }

    // MARK: - Enhanced Query API

    /// Get sentences for any grammar point using database predicates
    func getSentencesForGrammar(_ grammarId: String) -> [SentenceLocal] {
        sentenceStore.getSentencesForGrammar(grammarId)
    }

    /// Get all grammar points in SRS with their sentence counts
    func getGrammarWithSentenceCounts() -> [(GrammarPointLocal, Int)] {
        let inSRSItems = inSRSGrammarItems
        return inSRSItems.map { grammar in
            let sentenceCount = sentenceStore.getSentencesForGrammar(grammar.id).count
            return (grammar, sentenceCount)
        }
    }

    /// Get usage analytics across all stores
    func getStudyAnalytics() async -> StudyAnalytics {
        let grammarStats = await grammarStore.getGrammarUsageAnalytics()
        let sentenceStats = await sentenceStore.getGrammarUsageStats()
        let dueRecords = srsStore.getRecordsDueForReview()

        return StudyAnalytics(
            totalGrammarPoints: grammarStats.totalPoints,
            systemGrammarPoints: grammarStats.systemPoints,
            userGrammarPoints: grammarStats.userPoints,
            totalSRSRecords: srsStore.srsRecords.count,
            recordsDue: dueRecords.count,
            totalSentences: sentenceStore.sentences.count,
            mostUsedGrammar: sentenceStats.max(by: { $0.value < $1.value })?.key,
        )
    }

    // MARK: - Sync Boilerplate

    /// Performs full data refresh with remote sync
    func refresh() async {
        await grammarStore.refresh()
        await srsStore.refresh()
        await sentenceStore.refresh()
    }

    /// Clear all in memory data
    func clearInMemoryData() {
        grammarStore.clearInMemoryData()
        srsStore.clearInMemoryData()
        sentenceStore.clearInMemoryData()
    }
}

// MARK: - Study Analytics

struct StudyAnalytics {
    let totalGrammarPoints: Int
    let systemGrammarPoints: Int
    let userGrammarPoints: Int
    let totalSRSRecords: Int
    let recordsDue: Int
    let totalSentences: Int
    let mostUsedGrammar: String?
}
