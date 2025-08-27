//
//  SwiftDataIntegrationTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi
import SwiftData
import Testing

@MainActor
struct SwiftDataIntegrationTests {
    @Test func schema_AllModelsAreValid() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let context = container.mainContext
        let grammarPoint = GrammarPointLocal(
            id: UUID(),
            context: "test",
            usage: "test",
            meaning: "test",
            tags: ["test", "test", "test"],
        )
        let journalEntry = JournalEntryLocal(
            id: UUID(),
            title: "test",
            content: "test",
            private: true,
            createdAt: Date(),
        )
        let sentence = SentenceLocal(
            id: UUID(),
            journalEntryId: UUID(),
            grammarId: UUID(),
            content: "test test test",
            createdAt: Date(),
        )

        // Run
        context.insert(grammarPoint)
        context.insert(journalEntry)
        context.insert(sentence)
        try context.save()

        // Verify can be fetched from the context
        let grammarResults = try context.fetch(FetchDescriptor<GrammarPointLocal>())
        let journalResults = try context.fetch(FetchDescriptor<JournalEntryLocal>())
        let sentenceResults = try context.fetch(FetchDescriptor<SentenceLocal>())
        #expect(grammarResults.count == 1)
        #expect(journalResults.count == 1)
        #expect(sentenceResults.count == 1)
    }
}
