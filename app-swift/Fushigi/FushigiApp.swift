//
//  FushigiApp.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftData
import SwiftUI
import TipKit

// MARK: - Fushigi App

/// Main app entry point for Fushigi language learning app
@main
struct FushigiApp: App {
    // MARK: - Shared Container

    /// Shared SwiftData container for persistent storage
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GrammarPointLocal.self,
            JournalEntryLocal.self,
            SentenceLocal.self,
            // SettingsLocal.self
        ])

        // For a real app, the data store should not only live in memory
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Stores and Init

    /// Grammar store for user grammars, daily random, and SRS
    @StateObject private var grammarStore: GrammarStore

    /// Grammar store for user grammars, daily random, and SRS
    @StateObject private var journalStore: JournalStore

    // Tag store of all user created tags linking journals to grammar
    @StateObject private var sentenceStore: SentenceStore

    // Settings store of all user settings
    // @StateObject private var settingsStore: SettingsStore

    /// Initialize app data stores
    init() {
        #if DEBUG
            // Comment out kill switch to wipe
            // wipeSwiftData(container: sharedModelContainer)
        #endif

        let context = sharedModelContainer.mainContext
        _grammarStore = StateObject(wrappedValue: GrammarStore(modelContext: context))
        _journalStore = StateObject(wrappedValue: JournalStore(modelContext: context))
        _sentenceStore = StateObject(wrappedValue: SentenceStore(modelContext: context))
        // _settingsStore = StateObject(wrappedValue: SettingsStore(modelContext: context))
    }

    /// Configure TipKit for user onboarding -- currently none
    func configureTips() async {
        do {
            try Tips.configure([
                // .cloudKitContainer(.named("iCloud.com.apple.Fushigi.tips")),
                .displayFrequency(.immediate),
            ])
        } catch {
            print("Unable to configure tips: \(error)")
        }
    }

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.mint)
                .environmentObject(grammarStore)
                .environmentObject(journalStore)
                .environmentObject(sentenceStore)
                // .environmentObject(settingsStore)
                .task {
                    await configureTips()
                    await grammarStore.refresh()
                    await journalStore.refresh()
                    await sentenceStore.refresh()

                    // TODO: Load sentences
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Debug Data Wipe

/// Wipe all data from persistent storage for debug mode
@MainActor
func wipeSwiftData(container: ModelContainer) {
    let context = container.mainContext

    do {
        try Tips.resetDatastore()
        try context.delete(model: GrammarPointLocal.self)
        try context.delete(model: JournalEntryLocal.self)
        try context.delete(model: SentenceLocal.self)
        // try context.delete(model: SettingsModel.self)

        try context.save()
        print("SwiftData store wiped successfully")
    } catch {
        print("Failed to wipe SwiftData: \(error)")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .withPreviewStores()
}
