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

@MainActor
func postEmailAuthRequest(_ request: EmailAuthRequest) async -> Result<AuthResponse, AuthError> {
    guard let url = URL(string: "\(APIConfig.currentBaseURL)/api/collections/users/auth-with-password") else {
        return .failure(.networkError("Invalid URL"))
    }

    do {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.networkError("Invalid response"))
        }

        if (200 ... 299).contains(httpResponse.statusCode) {
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return .success(authResponse)
            } catch {
                return .failure(.decodingError)
            }
        } else {
            if let errorResponse = try? JSONDecoder().decode(PocketBaseError.self, from: data) {
                return .failure(.serverError(errorResponse.message))
            } else {
                return .failure(.serverError("Authentication failed"))
            }
        }

    } catch {
        if error is URLError {
            return .failure(.networkError(error.localizedDescription))
        }
        return .failure(.networkError("Unknown network error"))
    }
}

@MainActor
func postAppleAuthRequest(_ request: AppleAuthRequest) async -> Result<AuthResponse, AuthError> {
    guard let url = URL(string: "\(APIConfig.currentBaseURL)/api/collections/users/auth-with-oauth2") else {
        return .failure(.networkError("Invalid URL"))
    }

    do {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.networkError("Invalid response"))
        }

        if (200 ... 299).contains(httpResponse.statusCode) {
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return .success(authResponse)
            } catch {
                return .failure(.decodingError)
            }
        } else {
            if let errorResponse = try? JSONDecoder().decode(PocketBaseError.self, from: data) {
                return .failure(.serverError(errorResponse.message))
            } else {
                return .failure(.serverError("Apple Sign-In failed"))
            }
        }

    } catch {
        if error is URLError {
            return .failure(.networkError(error.localizedDescription))
        }
        return .failure(.networkError("Unknown network error"))
    }
}
