//
//  AuthAPI.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/26.
//

import Foundation

@MainActor
func postEmailAuthRequest(_ request: EmailAuthRequest) async -> Result<AuthResponse, AuthError> {
    guard let url = URL(string: "\(APIConfig.demoURL)/api/collections/users/auth-with-password") else {
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
    guard let url = URL(string: "\(APIConfig.demoURL)/api/collections/users/auth-with-oauth2") else {
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
