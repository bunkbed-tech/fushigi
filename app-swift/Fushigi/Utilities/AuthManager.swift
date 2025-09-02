//
//  AuthManager.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/02.
//

import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AuthRecord?
    @Published var token: String?

    init() {
        loadStoredAuth()
    }

    func login(with authResponse: AuthResponse) {
        currentUser = authResponse.record
        token = authResponse.token
        isAuthenticated = true
        KeychainHelper.shared.save(authResponse.token, forKey: "pbToken")
    }

    func logout() {
        currentUser = nil
        token = nil
        isAuthenticated = false
        KeychainHelper.shared.delete(forKey: "pbToken")
    }

    private func loadStoredAuth() {
        if let storedToken = KeychainHelper.shared.load(forKey: "pbToken") {
            token = storedToken
            isAuthenticated = true
            // TODO: Verify with Pocketbase? Refresh?
        }
    }

    func refreshUserInfo() async {
        //guard let token else { return }
        // TODO: Verify with Pocketbase? Refresh?
        // TODO: Update currentUser if successful
        // TODO: Set isAuthenticated = false if token is invalid
    }
}
