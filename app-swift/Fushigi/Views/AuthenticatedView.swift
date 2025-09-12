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

/// App wrapper view post authentication adding in iCloud and data model features. By default this type of code is
/// provided by Apple as boilerplate when beginning a new project. I want to force it to occur after a user actually
/// signs in and is authorized.
struct AuthenticatedView: View {
    // MARK: - Published State

    @ObservedObject var authManager: AuthManager
    @StateObject private var studyStore: StudyStore
    @StateObject private var journalStore: JournalStore
    @StateObject private var sentenceStore: SentenceStore

    // MARK: - Init

    /// Shared SwiftData container for persistent storage across app open/close
    private let sharedModelContainer: ModelContainer

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
            // Comment out kill switch to wipe data while testing
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

    // MARK: - Main View

    var body: some View {
        AppNavigatorView()
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

    // MARK: - Helper Methods

    /// Configure TipKit for user onboarding. None are implemented right now due to bugs related to unclosed tips
    /// showing up on the incorrect view when navigating to a new tab on iOS. I left it in on purpose as dead code
    /// just as a reminder to come back to it later.
    ///
    /// TODO: Figure out how to properly implement tips and implement a user onboarding experience with them.
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
