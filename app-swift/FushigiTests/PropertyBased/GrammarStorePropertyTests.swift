//
//  GrammarStorePropertyTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi
import Testing

@MainActor
struct GrammarStorePropertyTests {
    @Test func filterGrammarPoints_AlwaysReturnsSubsetOrEqual() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep Data
        store.grammarItems = MockedData.createMockGrammarPoints()
        let searchTerms = ["formal", "greeting", "nonexistent", "", "FORMAL"]

        // Run
        for term in searchTerms {
            let filtered = store.filterGrammarPoints(containing: term)

            // Verify
            #expect(filtered.count <= store.grammarItems.count)
            if term.isEmpty {
                #expect(filtered.count == store.grammarItems.count)
            }
        }
    }

    @Test func updateRandomGrammarPoints_NeverExceedsFive() async throws {
        // Prep data
        let dataSizes = [0, 1, 3, 5, 10, 100]

        for size in dataSizes {
            let testData = (0 ..< size).map { idx in
                GrammarPointLocal(
                    id: UUID(),
                    context: "Context \(idx)",
                    usage: "Usage \(idx)",
                    meaning: "Meaning \(idx)",
                    tags: ["tag\(idx)"],
                )
            }

            // Setup
            let container = try MockedModelContainer.createInMemoryContainer()
            let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)
            store.grammarItems = testData

            // Run
            store.updateRandomGrammarPoints(force: true)

            // Verify
            #expect(store.randomGrammarItems.count <= min(5, testData.count))
        }
    }
}
