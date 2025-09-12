//
//  FushigiApp.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Fushigi App

/// Main app entry point for Fushigi language learning app. The intent of this app is to target
/// language learners stuck at the "Intermediate Plateau". This is done by trying to enforce
/// a daily "journaling" habit where they use suggested "grammar points" and tag their usages
/// to slowly build a sentence bank over time. Filters are provided to get a different set of more
/// targeted grammar points in a given session. Due to the high likelihood users will write contrived
/// sentences just to satisfy the suggestions of the day, it is more beneficial to think of this app as
/// a Guided Sentence Pattern Practice Tool of sorts.
///
/// Future features include an AI based "grader" to help influence the daily SRS calculation more
/// than a simple studied vs. not-studied recently algorithm, as well as a potential social networking
/// ability to read and comment on your friends posts.
@main
struct FushigiApp: App {
    /// Stores current state of the logged in user + authentication on the PocketBase backend
    @StateObject private var authManager = AuthManager()

    // MARK: - Main View

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                AuthenticatedView(authManager: authManager)
            } else {
                LoginView(authManager: authManager)
            }
        }

        #if os(macOS)
            Settings { SettingsWindow() }
        #endif
    }
}

// MARK: - Preview

#Preview("Login Page") {
    LoginView(authManager: AuthManager())
}
