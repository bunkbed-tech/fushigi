//
//  GrammarStoreUnitTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi
import Testing

@MainActor
struct GrammarStoreUnitTests {
    // MARK: - syncWithRemote()

    @Test func syncWithRemote_Success_UpdatesItems() async throws {
        // Prep data
        let remoteData = [
            GrammarPointRemote(
                id: UUID(),
                context: "Remote context",
                usage: "Remote usage",
                meaning: "Remote meaning",
                tags: ["remote"],
            ),
        ]

        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(
            remoteService: MockRemoteGrammarDataService().withSuccess(remoteData),
            modelContext: container.mainContext,
        )

        // Run
        await store.syncWithRemote()

        // Verify
        #expect(store.grammarItems.count == 1)
        #expect(store.grammarItems.first?.usage == "Remote usage")
        #expect(store.systemHealth == .healthy)
        #expect(store.lastSyncDate != nil)
    }

    @Test func syncWithRemote_ErrorHandlesGracefully() async throws {
        // Setup
        let error = NSError(domain: "TestError", code: 1)
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(
            remoteService: MockRemoteGrammarDataService().withError(error),
            modelContext: container.mainContext,
        )

        // Run
        await store.syncWithRemote()

        // Verify
        #expect(store.systemHealth == .pocketbaseError)
    }

    // MARK: - loadLocal()

    @MainActor
    @Test func loadLocal_ValidOnEmptyContext() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Verify
        #expect(store.grammarItems.isEmpty)

        // Run
        await store.loadLocal()

        // Verify
        #expect(store.grammarItems.isEmpty)
    }

    @MainActor
    @Test func loadLocal_PopulatesPublishedPropertiesFromContext() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        let item = GrammarPointLocal(id: UUID(), context: "new", usage: "new", meaning: "new", tags: ["new"])
        container.mainContext.insert(item)
        try container.mainContext.save()

        // Run
        await store.loadLocal()

        // Verify
        #expect(store.grammarItems.count == 1)
        #expect(store.grammarItems.first?.context == "new")
        #expect(store.grammarItems.first?.usage == "new")
        #expect(store.grammarItems.first?.meaning == "new")
        #expect(store.grammarItems.first?.tags == ["new"])
    }

    // MARK: - processRemotePoints()

    @MainActor
    @Test func processRemotePoints_UpdatesExistingItems() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        let existingId = UUID()
        let existingItem = GrammarPointLocal(
            id: existingId,
            context: "old",
            usage: "old",
            meaning: "old",
            tags: ["old"],
        )

        // Force insert to mock a previously successful data load
        container.mainContext.insert(existingItem)
        try container.mainContext.save()

        // Make sure to load it into Published properties which would have also happened
        await store.loadLocal()

        // Prep new data in a format coming from the remote server
        let remoteUpdate = GrammarPointRemote(
            id: existingId,
            context: "new",
            usage: "new",
            meaning: "new",
            tags: ["new"],
        )

        // Run
        await store.processRemotePoints([remoteUpdate])

        // Verify
        #expect(store.grammarItems.count == 1)
        #expect(store.grammarItems.first?.context == "new")
        #expect(store.grammarItems.first?.usage == "new")
    }

    @MainActor
    @Test func processRemotePoints_AddsNewItems() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        let newRemoteItem = GrammarPointRemote(
            id: UUID(),
            context: "new",
            usage: "new",
            meaning: "new",
            tags: ["new"],
        )

        // Run
        await store.processRemotePoints([newRemoteItem])

        // Verify
        #expect(store.grammarItems.count == 1)
        #expect(store.grammarItems.first?.context == "new")
    }

    // MARK: - Data Filtering Tests

    @MainActor
    @Test func filterGrammarPoints_NoSearchTextReturnsAll() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        store.grammarItems = MockedData.createMockGrammarPoints()

        // Run
        let filtered = store.filterGrammarPoints()

        // Verify
        #expect(filtered.count == store.grammarItems.count)
        #expect(filtered.count == 6)
    }

    /// Verify filtering by usage text finds matching items case-insensitively
    @Test func filterGrammarPoints_ByUsage_FindsMatches() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        store.grammarItems = [
            GrammarPointLocal(id: UUID(), context: "formal", usage: "です", meaning: "copula", tags: ["grammar"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "だ", meaning: "copula", tags: ["grammar"]),
            GrammarPointLocal(id: UUID(), context: "question", usage: "か", meaning: "particle", tags: ["particle"]),
        ]

        // Run
        let filtered = store.filterGrammarPoints(containing: "particle")

        // Verify
        #expect(filtered.count == 1)
        #expect(filtered.first?.meaning == "particle")
    }

    // MARK: - Subset Management Tests

    @Test func updateRandomGrammarPoints_RespectsMaximumCount() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        store.grammarItems = MockedData.createMockGrammarPoints()

        // Run
        store.updateRandomGrammarPoints(force: true)

        // Verify
        #expect(store.grammarItems.count == 6)
        #expect(store.randomGrammarItems.count == 5)
    }

    @Test func updateAlgorithmicGrammarPoints_RespectsMaximumCount() async throws {
        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        store.grammarItems = MockedData.createMockGrammarPoints()

        // Run
        store.updateAlgorithmicGrammarPoints(force: true)

        // Verify
        #expect(store.grammarItems.count == 6)
        #expect(store.algorithmicGrammarItems.count == 5)
    }

    @Test func getGrammarPoints_ReturnsCorrectSubset() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(remoteService: MockRemoteGrammarDataService(), modelContext: container.mainContext)

        // Prep data
        let mockData = MockedData.createMockGrammarPoints()

        store.setRandomGrammarPointsForPreview(Array(mockData.prefix(2)))
        store.setAlgorithmicGrammarPointsForPreview(Array(mockData.suffix(3)))

        let randomPoints = store.getGrammarPoints(for: .random)
        let srsPoints = store.getGrammarPoints(for: .srs)

        // Verify
        #expect(randomPoints.count == 2)
        #expect(srsPoints.count == 3)
    }

    // MARK: - Comprehensive Operation Tests

    @MainActor
    @Test func refresh_CallsAllOperations() async throws {
        // Prep data
        let remoteData = [
            GrammarPointRemote(
                id: UUID(),
                context: "Remote",
                usage: "Remote",
                meaning: "Remote",
                tags: ["remote"],
            ),
        ]

        // Set up
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(
            remoteService: MockRemoteGrammarDataService().withSuccess(remoteData),
            modelContext: container.mainContext,
        )

        // Run
        await store.refresh()

        // Verify
        #expect(store.grammarItems.count == remoteData.count)
        #expect(!store.randomGrammarItems.isEmpty)
        #expect(!store.algorithmicGrammarItems.isEmpty)
    }
}
