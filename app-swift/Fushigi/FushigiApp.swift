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
    /// Current login state of user
    @State private var userSession: UserSession?

    var body: some Scene {
        WindowGroup {
            if let session = userSession {
                // User is authenticated - show main app
                AuthenticatedAppView(userSession: session)
            } else {
                // Show login screen
                LoginPage { session in
                    userSession = session
                }
            }
        }
    }
}

// MARK: - Authenticated App View

struct AuthenticatedAppView: View {
    /// Current login state of user
    @ObservedObject var userSession: UserSession

    /// Grammar store for user grammars, daily random, and SRS
    @StateObject private var grammarStore: GrammarStore

    /// Grammar store for user grammars, daily random, and SRS
    @StateObject private var journalStore: JournalStore

    // Tag store of all user created tags linking journals to grammar
    @StateObject private var sentenceStore: SentenceStore

    /// Shared SwiftData container for persistent storage
    private let sharedModelContainer: ModelContainer

    /// Initialize app data stores
    init(userSession: UserSession) {
        self.userSession = userSession

        // Create container once
        let schema = Schema([
            GrammarPointLocal.self,
            JournalEntryLocal.self,
            SentenceLocal.self,
        ])

        let modelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .private("iCloud.tech.bunkbed.fushigi"),
        )
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration],
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        #if DEBUG
            // Comment out kill switch to wipe
            // wipeSwiftData(container: sharedModelContainer)
        #endif

        let context = sharedModelContainer.mainContext
        _grammarStore = StateObject(wrappedValue: GrammarStore(modelContext: context))
        _journalStore = StateObject(wrappedValue: JournalStore(modelContext: context))
        _sentenceStore = StateObject(wrappedValue: SentenceStore(modelContext: context))
    }

    var body: some View {
        ContentView()
            .modelContainer(sharedModelContainer)
            .environmentObject(userSession)
            .environmentObject(grammarStore)
            .environmentObject(journalStore)
            .environmentObject(sentenceStore)
            .tint(.mint)
            .task {
                await configureTips()
                await grammarStore.refresh()
                await journalStore.refresh()
                await sentenceStore.refresh()
            }
    }

    /// Configure TipKit for user onboarding -- currently none
    func configureTips() async {
        do {
            try Tips.configure([
                // .cloudKitContainer(.named("iCloud.tech.bunkbed.Fushigi.tips")),
                .displayFrequency(.immediate),
            ])
        } catch {
            print("Unable to configure tips: \(error)")
        }
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

#Preview("Login Page") {
    LoginPage { session in
        print("Preview login: \(session.providerUserId)")
    }
}
