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

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // User is authenticated - show main app
                AuthenticatedView(authManager: authManager)
            } else {
                // Show login screen
                LoginPage(authManager: authManager)
            }
        }
    }
}

// MARK: - Preview

#Preview("Login Page") {
    LoginPage(authManager: AuthManager())
}
