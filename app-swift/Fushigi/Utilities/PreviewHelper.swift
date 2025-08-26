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
        @ViewBuilder content: @escaping (GrammarStore, JournalStore, SentenceStore) -> some View,
    ) -> some View {
        do {
            // for previews, we only want the data store to only live in memory while testing
            let container = try ModelContainer(
                for: Schema([GrammarPointLocal.self, JournalEntryLocal.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)],
            )
            let grammarStore = GrammarStore(modelContext: container.mainContext)
            let journalStore = JournalStore(modelContext: container.mainContext)
            let sentenceStore = SentenceStore(modelContext: container.mainContext)

            // Configure store with fake data based on preview mode
            configureStoresForPreviewMode(
                grammarStore: grammarStore,
                journalStore: journalStore,
                sentenceStore: sentenceStore,
                dataAvailability: dataAvailability,
                systemHealth: systemHealth,
            )

            return AnyView(
                content(grammarStore, journalStore, sentenceStore)
                    .environmentObject(grammarStore)
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
        grammarStore: GrammarStore,
        journalStore: JournalStore,
        sentenceStore: SentenceStore,
        dataAvailability: DataAvailability,
        systemHealth: SystemHealth,
    ) {
        switch dataAvailability {
        case .empty, .loading:
            grammarStore.grammarItems = []
            journalStore.journalEntries = []
            sentenceStore.sentences = []
        case .available:
            setupGrammar(grammarStore)
            setupJournal(journalStore)
            setupSentences(sentenceStore)
        }

        // Just force systemHealth to whatever was provided
        grammarStore.dataAvailability = dataAvailability
        journalStore.dataAvailability = dataAvailability
        sentenceStore.dataAvailability = dataAvailability
        grammarStore.systemHealth = systemHealth
        journalStore.systemHealth = systemHealth
        sentenceStore.systemHealth = systemHealth
    }

    /// Load preview store with fake grammar data
    @MainActor
    private static func setupGrammar(_ store: GrammarStore) {
        let fakeItems = [
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Hello", meaning: "こんにちは", tags: ["greeting"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Goodbye", meaning: "さようなら", tags: ["farewell"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "I", meaning: "私は", tags: ["context"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Cool", meaning: "かっこいい", tags: ["adjective"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Am", meaning: "desu", tags: ["sentence-ender"]),
        ]

        store.grammarItems = fakeItems
        store.setRandomGrammarPointsForPreview(Array(fakeItems.shuffled().prefix(5)))
        store.setAlgorithmicGrammarPointsForPreview(Array(fakeItems.shuffled().prefix(5)))
    }

    /// Load preview store with fake journal data
    @MainActor
    private static func setupJournal(_ store: JournalStore) {
        let fakeItems = [
            JournalEntryLocal(
                id: UUID(),
                title: "Hello 1",
                content: "Blah blah blah.",
                private: false,
                createdAt: Date(),
            ),
            JournalEntryLocal(
                id: UUID(),
                title: "Hello 2",
                content: "Blah blah blah.",
                private: false,
                createdAt: Date(),
            ),
            JournalEntryLocal(
                id: UUID(),
                title: "Hello 3",
                content: "Blah blah blah.",
                private: false,
                createdAt: Date(),
            ),
            JournalEntryLocal(
                id: UUID(),
                title: "Hello 4",
                content: "Blah blah blah.",
                private: false,
                createdAt: Date(),
            ),
            JournalEntryLocal(
                id: UUID(),
                title: "Hello 5",
                content: "Blah blah blah.",
                private: false,
                createdAt: Date(),
            ),
        ]

        store.journalEntries = fakeItems
    }

    /// Load preview store with fake sentence data
    @MainActor
    private static func setupSentences(_ store: SentenceStore) {
        let fakeItems = [
            SentenceLocal(
                id: UUID(),
                journalEntryId: UUID(),
                grammarId: UUID(),
                content: "Test sentence 2.",
                createdAt: Date(),
            ),
            SentenceLocal(
                id: UUID(),
                journalEntryId: UUID(),
                grammarId: UUID(),
                content: "Test sentence 2.",
                createdAt: Date(),
            ),
            SentenceLocal(
                id: UUID(),
                journalEntryId: UUID(),
                grammarId: UUID(),
                content: "Test sentence 3.",
                createdAt: Date(),
            ),
            SentenceLocal(
                id: UUID(),
                journalEntryId: UUID(),
                grammarId: UUID(),
                content: "Test sentence 4.",
                createdAt: Date(),
            ),
            SentenceLocal(
                id: UUID(),
                journalEntryId: UUID(),
                grammarId: UUID(),
                content: "Test sentence 5.",
                createdAt: Date(),
            ),
        ]

        store.sentences = fakeItems
    }
}
