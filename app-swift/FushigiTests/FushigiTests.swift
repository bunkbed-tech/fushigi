//
//  FushigiTests.swift
//  FushigiTests
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
@testable import Fushigi
import SwiftData
import Testing

// MARK: - Testing Example Structure

struct FushigiTests {
    @Test func example() async throws {
        // Use APIs like `#expect(...)` to check expected conditions
    }

    @MainActor
    @Test func sanityCheckInsertFetch() async throws {
        let container = try MockedModelContainer.createInMemoryContainer()
        let ctx = container.mainContext
        let item = GrammarPointLocal(id: UUID(), context: "ctx", usage: "u", meaning: "m", tags: ["t"])
        ctx.insert(item)
        try ctx.save()
        let results = try ctx.fetch(FetchDescriptor<GrammarPointLocal>())
        #expect(results.count == 1)
    }

    @MainActor
    @Test func storeInsertAndFetchGrammarPoint() async throws {
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)
        let item = GrammarPointLocal(
            id: UUID(),
            context: "test-context",
            usage: "test-usage",
            meaning: "test-meaning",
            tags: ["test-tag"],
        )
        container.mainContext.insert(item)
        try container.mainContext.save()
        await store.loadLocal()
        #expect(store.grammarItems.count == 1)
        #expect(store.grammarItems.first?.context == "test-context")
        #expect(store.grammarItems.first?.usage == "test-usage")
        #expect(store.grammarItems.first?.meaning == "test-meaning")
        #expect(store.grammarItems.first?.tags == ["test-tag"])
    }
}
