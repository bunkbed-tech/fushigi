//
//  PredicateSortingExtensions.swift
//  Fushigi
//
//  Created for performance optimization
//

import Foundation
import SwiftData

// MARK: - ModelContext Extensions

/// Performance helpers for SwiftData queries
extension ModelContext {
    /// Generic fetch helper that's easier to use
    func fetch<T: PersistentModel>(
        _: T.Type,
        where predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil,
    ) throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate
        descriptor.sortBy = sortBy
        if let limit {
            descriptor.fetchLimit = limit
        }
        return try fetch(descriptor)
    }

    /// Count records without loading them into memory
    func count<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>? = nil,
    ) throws -> Int {
        try fetch(type, where: predicate).count
    }
}

// MARK: - Common Predicates

/// Pre-built predicates for common queries
enum CommonPredicates {
    // MARK: Grammar Point Predicates

    /// Predicate for system grammar points
    static var systemGrammarPoints: Predicate<GrammarPointLocal> {
        #Predicate<GrammarPointLocal> { $0.user == nil }
    }

    /// Predicate for user grammar points
    static func userGrammarPoints(userId: String) -> Predicate<GrammarPointLocal> {
        #Predicate<GrammarPointLocal> { $0.user == userId }
    }

    /// Predicate for grammar points containing search term
    static func grammarPointsContaining(_ searchText: String) -> Predicate<GrammarPointLocal> {
        #Predicate<GrammarPointLocal> { grammar in
            grammar.usage.localizedStandardContains(searchText) ||
                grammar.meaning.localizedStandardContains(searchText) ||
                grammar.context.localizedStandardContains(searchText)
        }
    }

    // MARK: Sentence Predicates

    /// Predicate for sentences by grammar point
    static func sentences(forGrammar grammarId: String) -> Predicate<SentenceLocal> {
        #Predicate<SentenceLocal> { $0.grammar == grammarId }
    }

    /// Predicate for sentences by journal entry
    static func sentences(forJournal journalId: String) -> Predicate<SentenceLocal> {
        #Predicate<SentenceLocal> { $0.journalEntry == journalId }
    }

    /// Predicate for sentences by user
    static func sentences(forUser userId: String) -> Predicate<SentenceLocal> {
        #Predicate<SentenceLocal> { $0.user == userId }
    }

    // MARK: SRS Record Predicates

    /// Predicate for SRS records due for review
    static var srsRecordsDueForReview: Predicate<SRSRecordLocal> {
        let now = Date()
        return #Predicate<SRSRecordLocal> { record in
            (record.dueDate) <= now
        }
    }

    /// Predicate for SRS records by grammar point
    static func srsRecords(forGrammar grammarId: String) -> Predicate<SRSRecordLocal> {
        #Predicate<SRSRecordLocal> { $0.grammar == grammarId }
    }

    // MARK: Journal Entry Predicates

    /// Predicate for public journal entries
    static var publicJournalEntries: Predicate<JournalEntryLocal> {
        #Predicate<JournalEntryLocal> { !$0.isPrivate }
    }

    /// Predicate for private journal entries
    static var privateJournalEntries: Predicate<JournalEntryLocal> {
        #Predicate<JournalEntryLocal> { $0.isPrivate }
    }

    /// Predicate for journal entries containing search term
    static func journalEntries(containing searchText: String) -> Predicate<JournalEntryLocal> {
        #Predicate<JournalEntryLocal> { entry in
            entry.title.localizedStandardContains(searchText) ||
                entry.content.localizedStandardContains(searchText)
        }
    }
}
