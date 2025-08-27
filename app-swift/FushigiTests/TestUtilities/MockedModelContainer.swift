//
//  MockedModelContainer.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

@testable import Fushigi
import SwiftData

@MainActor
struct MockedModelContainer {
    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            GrammarPointLocal.self,
            JournalEntryLocal.self,
            SentenceLocal.self,
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)],
        )
    }
}
