//
//  AuthManager.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/02.
//

import Foundation
import SwiftUI

// MARK: - Auth Manager

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
        // guard let token else { return }
        // TODO: Verify with Pocketbase? Refresh?
        // TODO: Update currentUser if successful
        // TODO: Set isAuthenticated = false if token is invalid
    }
}

// MARK: - Routes

@MainActor
func postAuthRequest<T: Decodable>(
    endpoint: String,
    requestBody: some Encodable,
) async -> Result<T, AuthError> {
    guard let url = URL(string: "\(APIConfig.baseURL)/api/collections/users/\(endpoint)") else {
        return .failure(.networkError("Invalid URL"))
    }

    do {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.networkError("Invalid response"))
        }

        return try handle(T.self, data: data, status: httpResponse.statusCode)

    } catch {
        return .failure(.networkError("Network request failed", underlying: error))
    }
}

private func handle<T: Decodable>(_: T.Type, data: Data, status: Int) throws -> Result<T, AuthError> {
    if (200 ... 299).contains(status) {
        decode(T.self, from: data)
    } else if let pbError = try? JSONDecoder.pocketBase.decode(PocketBaseError.self, from: data) {
        .failure(.serverError(pbError.message))
    } else {
        .failure(.serverError("Unknown server error"))
    }
}

private func decode<T: Decodable>(_: T.Type, from data: Data) -> Result<T, AuthError> {
    do {
        return try .success(JSONDecoder.pocketBase.decode(T.self, from: data))
    } catch {
        if let json = String(data: data, encoding: .utf8) {
            print("Failed to decode \(T.self), raw JSON: \(json)")
        }
        return .failure(.decodingError("Failed to decode \(T.self)", underlying: error))
    }
}

// MARK: - Endpoints

@MainActor
func postEmailAuthRequest(_ request: EmailAuthRequest) async -> Result<AuthResponse, AuthError> {
    await postAuthRequest(endpoint: "auth-with-password", requestBody: request)
}

@MainActor
func postAppleAuthRequest(_ request: AppleAuthRequest) async -> Result<AuthResponse, AuthError> {
    await postAuthRequest(endpoint: "auth-with-oauth2", requestBody: request)
}
