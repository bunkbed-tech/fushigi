//
//  Auth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation

// Configuration
enum APIConfig {
    static let demoURL = "https://demo.fushigi.bunkbed.tech"
    static let prodURL = "https://fushigi.bunkbed.tech"

    static var currentBaseURL: String {
        // TODO: Check environment variable
        #if DEBUG
            return demoURL
        #else
            return prodURL
        #endif
    }
}

struct EmailAuthRequest: Codable {
    let identity: String
    let password: String
}

struct AppleAuthRequest: Codable {
    let provider: String
    let code: String
    let codeVerifier: String
    let redirectURL: String

    init(identityToken: String, userID: String) {
        provider = "apple"
        code = identityToken
        codeVerifier = userID
        redirectURL = "http://demo.fushigi.bunkbed.tech/api/oauth2-redirect"
    }
}

struct AuthRecord: Decodable {
    let id: String
    let email: String
    let collectionId: String
    let collectionName: String
    let created: Date
    let updated: Date
    let verified: Bool
    let emailVisibility: Bool
    let avatar: String
    let name: String
}

struct AuthResponse: Decodable {
    let record: AuthRecord
    let token: String
}

struct PocketBaseError: Decodable {
    let code: Int
    let message: String
    let data: [String: String]?
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case serverError(String)
    case decodingError
    case tokenStorageError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Invalid email or password"
        case let .networkError(message):
            "Network error: \(message)"
        case let .serverError(message):
            "Server error: \(message)"
        case .decodingError:
            "Unable to process server response"
        case .tokenStorageError:
            "Failed to store authentication token"
        }
    }
}
