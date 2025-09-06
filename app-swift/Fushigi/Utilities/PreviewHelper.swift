//
//  PreviewHelper.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/14.
//  Utilized AI to figure out how to do this. Not sure how to improve/simplify.
//

import SwiftData
import SwiftUI

// MARK: - Preview Helper

enum PreviewHelper {
    /// Create fake data store for Preview mode with various configurations
    @MainActor
    static func withStore(
        dataAvailability: DataAvailability = .available,
        systemHealth: SystemHealth = .healthy,
        systemState: SystemState = .normal,
        @ViewBuilder content: @escaping (JournalStore, SentenceStore, StudyStore) -> some View,
    ) -> some View {
        do {
            // for previews, we only want the data store to only live in memory while testing
            let container = try ModelContainer(
                for: Schema([GrammarPointLocal.self, JournalEntryLocal.self, SentenceLocal.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)],
            )
            let journalStore = JournalStore(modelContext: container.mainContext, authManager: AuthManager())
            let sentenceStore = SentenceStore(modelContext: container.mainContext, authManager: AuthManager())
            let studyStore = StudyStore(modelContext: container.mainContext, authManager: AuthManager())

            // Configure store with fake data based on preview mode
            configureStoresForPreviewMode(
                journalStore: journalStore,
                sentenceStore: sentenceStore,
                studyStore: studyStore,
                dataAvailability: dataAvailability,
                systemHealth: systemHealth,
                systemState: systemState,
            )

            return AnyView(
                content(journalStore, sentenceStore, studyStore)
                    .environmentObject(studyStore)
                    .environmentObject(studyStore.grammarStore)
                    .environmentObject(studyStore.srsStore)
                    .environmentObject(journalStore)
                    .environmentObject(sentenceStore)
                    .modelContainer(container),
            )
        } catch {
            return AnyView(
                Text("Preview Error: \(error.localizedDescription)")
                    .foregroundColor(.red),
            )
        }
    }

    /// Configure grammar store for different preview modes
    @MainActor
    private static func configureStoresForPreviewMode(
        journalStore: JournalStore,
        sentenceStore: SentenceStore,
        studyStore: StudyStore,
        dataAvailability: DataAvailability,
        systemHealth: SystemHealth,
        systemState: SystemState,
    ) {
        print("PREVIEW DEBUG:")
        print("   dataAvailability: \(dataAvailability)")
        print("   systemState param: \(systemState)")
        print("   systemHealth: \(systemHealth)")

        switch dataAvailability {
        case .empty, .loading:
            studyStore.grammarStore.grammarItems = []
            studyStore.srsStore.srsRecords = []
            journalStore.journalEntries = []
            sentenceStore.sentences = []
            print("   → Set all stores to empty arrays")
        case .available:
            if systemState == .emptySRS {
                setupGrammarOnly(studyStore)
                print("   → Setup grammar only, SRS records: \(studyStore.srsStore.srsRecords.count)")
            } else {
                setupGrammar(studyStore)
                print(
                    "   → Setup both, Grammar: \(studyStore.grammarStore.grammarItems.count), SRS: \(studyStore.srsStore.srsRecords.count)",
                )
            }
            setupJournal(journalStore)
            setupSentences(sentenceStore)
            print("   → Setup journal and sentences")
        }

        // Set data availability based on systemState
        if systemState == .emptySRS {
            studyStore.grammarStore.dataAvailability = .available
            studyStore.srsStore.dataAvailability = .empty // This should trigger .emptySRS
            journalStore.dataAvailability = dataAvailability
            sentenceStore.dataAvailability = dataAvailability
            print("   → Set grammar=available, srs=empty for emptySRS")
        } else {
            studyStore.grammarStore.dataAvailability = dataAvailability
            studyStore.srsStore.dataAvailability = dataAvailability
            journalStore.dataAvailability = dataAvailability
            sentenceStore.dataAvailability = dataAvailability
            print("   → Set all stores to \(dataAvailability)")
        }

        // Set system health for all stores
        studyStore.grammarStore.systemHealth = systemHealth
        studyStore.srsStore.systemHealth = systemHealth
        journalStore.systemHealth = systemHealth
        sentenceStore.systemHealth = systemHealth
        print("   → Set all stores systemHealth to \(systemHealth)")

        // Debug final states
        print("   Final grammar systemState: \(studyStore.grammarStore.systemState)")
        print("   Final srs systemState: \(studyStore.srsStore.systemState)")
        print("   Final study systemState: \(studyStore.systemState)")
    }

    /// Load preview store with fake grammar data AND SRS records with proper relationships
    @MainActor
    private static func setupGrammar(_ store: StudyStore) {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        let id5 = UUID()
        let userID = UUID()

        let fakeItems = [
            GrammarPointLocal(id: id1, context: "casual", usage: "Hello", meaning: "こんにちは", tags: ["greeting"]),
            GrammarPointLocal(id: id2, context: "casual", usage: "Goodbye", meaning: "さようなら", tags: ["farewell"]),
            GrammarPointLocal(id: id3, context: "casual", usage: "I", meaning: "私は", tags: ["context"]),
            GrammarPointLocal(id: id4, context: "casual", usage: "Cool", meaning: "かっこいい", tags: ["adjective"]),
            GrammarPointLocal(id: id5, context: "casual", usage: "Am", meaning: "desu", tags: ["sentence-ender"]),
        ]

        // Create SRS records with proper relationships - different record IDs but grammar field matches grammar item
        // IDs
        let fakeRecords = [
            SRSRecordLocal(id: UUID(), user: userID, grammar: id1),
            SRSRecordLocal(id: UUID(), user: userID, grammar: id2),
            SRSRecordLocal(id: UUID(), user: userID, grammar: id3),
            SRSRecordLocal(id: UUID(), user: userID, grammar: id4),
            SRSRecordLocal(id: UUID(), user: userID, grammar: id5),
        ]

        store.grammarStore.grammarItems = fakeItems
        store.srsStore.srsRecords = fakeRecords
        store.srsStore.setRandomSRSRecordsForPreview(Array(fakeRecords.shuffled().prefix(5)))
        store.srsStore.setAlgorithmicSRSRecordsForPreview(Array(fakeRecords.shuffled().prefix(5)))
    }

    /// Load preview store with fake grammar data only (no SRS records)
    @MainActor
    private static func setupGrammarOnly(_ store: StudyStore) {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        let id5 = UUID()

        let fakeItems = [
            GrammarPointLocal(id: id1, context: "casual", usage: "Hello", meaning: "こんにちは", tags: ["greeting"]),
            GrammarPointLocal(id: id2, context: "casual", usage: "Goodbye", meaning: "さようなら", tags: ["farewell"]),
            GrammarPointLocal(id: id3, context: "casual", usage: "I", meaning: "私は", tags: ["context"]),
            GrammarPointLocal(id: id4, context: "casual", usage: "Cool", meaning: "かっこいい", tags: ["adjective"]),
            GrammarPointLocal(id: id5, context: "casual", usage: "Am", meaning: "desu", tags: ["sentence-ender"]),
        ]
        store.grammarStore.grammarItems = fakeItems
    }

    /// Load preview store with fake journal data
    @MainActor
    private static func setupJournal(_ store: JournalStore) {
        let fakeItems = [
            JournalEntryLocal(
                id: UUID().uuidString,
                user: "test-user",
                title: "Hello 1",
                content: "Blah blah blah.",
                isPrivate: false,
                created: Date(),
                updated: Date(),
            ),
            JournalEntryLocal(
                id: UUID().uuidString,
                user: "test-user",
                title: "Hello 2",
                content: "Blah blah blah.",
                isPrivate: false,
                created: Date(),
                updated: Date(),
            ),
            JournalEntryLocal(
                id: UUID().uuidString,
                user: "test-user",
                title: "Hello 3",
                content: "Blah blah blah.",
                isPrivate: false,
                created: Date(),
                updated: Date(),
            ),
            JournalEntryLocal(
                id: UUID().uuidString,
                user: "test-user",
                title: "Hello 4",
                content: "Blah blah blah.",
                isPrivate: false,
                created: Date(),
                updated: Date(),
            ),
            JournalEntryLocal(
                id: UUID().uuidString,
                user: "test-user",
                title: "Hello 5",
                content: "Blah blah blah.",
                isPrivate: false,
                created: Date(),
                updated: Date(),
            ),
        ]

        store.journalEntries = fakeItems
    }

    /// Load preview store with fake sentence data
    @MainActor
    private static func setupSentences(_ store: SentenceStore) {
        let fakeItems = [
            SentenceLocal(
                id: UUID().uuidString,
                user: "test-user",
                journalEntry: UUID().uuidString,
                grammar: UUID().uuidString,
                content: "Test sentence 1.",
                created: Date(),
                updated: Date(),
            ),
            SentenceLocal(
                id: UUID().uuidString,
                user: "test-user",
                journalEntry: UUID().uuidString,
                grammar: UUID().uuidString,
                content: "Test sentence 2.",
                created: Date(),
                updated: Date(),
            ),
            SentenceLocal(
                id: UUID().uuidString,
                user: "test-user",
                journalEntry: UUID().uuidString,
                grammar: UUID().uuidString,
                content: "Test sentence 3.",
                created: Date(),
                updated: Date(),
            ),
            SentenceLocal(
                id: UUID().uuidString,
                user: "test-user",
                journalEntry: UUID().uuidString,
                grammar: UUID().uuidString,
                content: "Test sentence 4.",
                created: Date(),
                updated: Date(),
            ),
            SentenceLocal(
                id: UUID().uuidString,
                user: "test-user",
                journalEntry: UUID().uuidString,
                grammar: UUID().uuidString,
                content: "Test sentence 5.",
                created: Date(),
                updated: Date(),
            ),
        ]

        store.sentences = fakeItems
    }
}
