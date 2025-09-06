//
//  AuthenticatedView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftData
import SwiftUI
import TipKit

// MARK: - Authenticated App View

struct AuthenticatedView: View {
    /// Current login state of user
    @ObservedObject var authManager: AuthManager

    /// Manages srs algorithm values for grammar points with local SwiftData storage and remote PocketBase sync
    @StateObject private var studyStore: StudyStore

    /// Grammar store for user grammars, daily random, and SRS
    @StateObject private var journalStore: JournalStore

    /// Tag store of all user created tags linking journals to grammar
    @StateObject private var sentenceStore: SentenceStore

    /// Shared SwiftData container for persistent storage
    private let sharedModelContainer: ModelContainer

    /// Initialize app data stores
    init(authManager: AuthManager) {
        self.authManager = authManager

        // Create container once
        let schema = Schema([
            GrammarPointLocal.self,
            JournalEntryLocal.self,
            SentenceLocal.self,
            SRSRecordLocal.self,
        ])

        let modelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .private("iCloud.tech.bunkbed.fushigi"),
        )

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

        _studyStore = StateObject(wrappedValue: StudyStore(
            modelContext: context,
            authManager: authManager,
        ))
        _journalStore = StateObject(wrappedValue: JournalStore(
            modelContext: context,
            authManager: authManager,
        ))
        _sentenceStore = StateObject(wrappedValue: SentenceStore(
            modelContext: context,
            authManager: authManager,
        ))
    }

    var body: some View {
        NavigationView()
            .modelContainer(sharedModelContainer)
            .environmentObject(authManager) // TODO: is this necessary?
            .environmentObject(studyStore)
            .environmentObject(studyStore.grammarStore)
            .environmentObject(studyStore.srsStore)
            .environmentObject(journalStore)
            .environmentObject(sentenceStore)
            .tint(.mint)
            .task {
                await configureTips()
                await studyStore.refresh()
                await journalStore.refresh()
                await sentenceStore.refresh()
                print("LOG: Sync and refresh complete")
                // TODO: should I add an authManager.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                wipeSwiftData(container: sharedModelContainer)
                journalStore.clearInMemoryData()
                sentenceStore.clearInMemoryData()
                studyStore.clearInMemoryData()
                authManager.clearInMemoryData()
                print("LOG: All data cleared from in-memory stores")
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
            print("ERROR: Unable to configure tips: \(error)")
        }
    }
}
