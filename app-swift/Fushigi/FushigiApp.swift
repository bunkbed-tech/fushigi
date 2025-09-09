//
//  FushigiApp.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Fushigi App

/// Main app entry point for Fushigi language learning app
@main
struct FushigiApp: App {
    /// Current login state of user
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
