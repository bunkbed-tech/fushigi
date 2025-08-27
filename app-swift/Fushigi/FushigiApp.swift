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
                AuthenticatedView(userSession: session)
            } else {
                // Show login screen
                LoginPage { session in
                    userSession = session
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Login Page") {
    LoginPage { session in
        print("Preview login: \(session.providerUserId)")
    }
}
