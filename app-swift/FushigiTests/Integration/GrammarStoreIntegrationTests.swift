//
//  GrammarStoreIntegrationTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi
import SwiftData
import Testing

@MainActor
struct GrammarStoreIntegrationTests {
    // MARK: - processRemotePoints()

    @Test
    func processRemotePoints_AddsToSwiftData() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        let remotePoints = [
            GrammarPointRemote(id: UUID(), context: "c1", usage: "u1", meaning: "m1", tags: ["t1"]),
            GrammarPointRemote(id: UUID(), context: "c2", usage: "u2", meaning: "m2", tags: ["t2"]),
        ]

        // Run
        await store.processRemotePoints(remotePoints)

        // Verify
        let results = try container.mainContext.fetch(FetchDescriptor<GrammarPointLocal>())
        #expect(results.count == 2)
    }

    @Test
    func processRemotePoints_SkipsDuplicates() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        let point = GrammarPointRemote(id: UUID(), context: "dup", usage: "dup", meaning: "dup", tags: [])

        // Run
        await store.processRemotePoints([point])
        await store.processRemotePoints([point])

        // Verify
        let results = try container.mainContext.fetch(FetchDescriptor<GrammarPointLocal>())
        #expect(results.count == 1)
    }

    @Test
    func processRemotePoints_RewritesOld() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        let id = UUID()
        let original = GrammarPointRemote(id: id, context: "old", usage: "old", meaning: "old", tags: [])
        let updated = GrammarPointRemote(id: id, context: "new", usage: "new", meaning: "new", tags: [])

        // Run
        await store.processRemotePoints([original])
        await store.processRemotePoints([updated])

        // Verify
        let results = try container.mainContext.fetch(FetchDescriptor<GrammarPointLocal>())
        #expect(results.count == 1)
        #expect(results.first?.context == "new")
    }

    // MARK: - loadLocal()

    @Test
    func loadLocal_InitialEmptyIsHealthy() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))

        // Run
        await store.loadLocal()

        // Verify
        #expect(store.systemHealth == .healthy)
        #expect(store.dataAvailability == .empty)
        #expect(store.systemState == .emptyData)
    }

    // MARK: - systemState

    @Test func systemState_EmptyToSwiftDataErrorIsCritical() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        store.dataAvailability = .empty
        store.systemHealth = .healthy

        // Verify
        #expect(store.systemState == .emptyData)

        // Switch to swift data error
        store.systemHealth = .swiftDataError

        // Verify
        if case let .criticalError(message) = store.systemState {
            #expect(message == SystemHealth.swiftDataError.description)
        } else {
            Issue.record("Expected critical error state")
        }
    }

    @Test func systemState_AvailableToSwiftDataErrorIsDegraded() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        store.dataAvailability = .available
        store.systemHealth = .healthy

        // Verify
        #expect(store.systemState == .normal)

        // Switch to swift data error
        store.systemHealth = .swiftDataError

        // Verify
        if case let .degradedOperation(message) = store.systemState {
            #expect(message == SystemHealth.swiftDataError.description)
        } else {
            Issue.record("Expected degraded operation state")
        }
    }

    @Test func setLoading_UpdatesAvailableToLoading() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))
        store.dataAvailability = .available

        // Run
        store.setLoading()

        // Verify
        #expect(store.dataAvailability == .loading)
    }

    @Test func handleLocalLoadFailure_UpdatesState() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: ModelContext(container))

        // Run
        store.handleLocalLoadFailure()

        // Verify
        #expect(store.systemHealth == .swiftDataError)
        #expect(store.dataAvailability == .empty)

        // Retry by now filling it with data
        store.grammarItems = MockedData.createMockGrammarPoints()
        store.handleLocalLoadFailure()

        // Verify
        #expect(store.systemHealth == .swiftDataError)
        #expect(store.dataAvailability == .available)
    }

    @Test func handleRemoteSyncFailure_UpdatesState() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: container.mainContext)

        // Run
        store.handleRemoteSyncFailure()

        // Verify
        #expect(store.systemHealth == .postgresError)
        #expect(store.dataAvailability == .empty)
    }

    @Test func handleSyncSuccess_ClearsPostgresError() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: container.mainContext)
        store.systemHealth = .postgresError
        store.grammarItems = MockedData.createMockGrammarPoints()

        // Run
        store.handleSyncSuccess()

        // Verify
        #expect(store.systemHealth == .healthy)
        #expect(store.dataAvailability == .available)
    }

    @Test func handleSyncSuccess_PreservesSwiftDataError() async throws {
        // Setup
        let container = try MockedModelContainer.createInMemoryContainer()
        let store = GrammarStore(modelContext: container.mainContext)
        store.systemHealth = .swiftDataError
        store.grammarItems = MockedData.createMockGrammarPoints()

        // Run
        store.handleSyncSuccess()

        // Verify
        #expect(store.systemHealth == .swiftDataError)
        #expect(store.dataAvailability == .available)
    }
}
