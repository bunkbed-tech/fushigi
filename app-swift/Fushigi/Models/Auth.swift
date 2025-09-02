//
//  Auth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation

enum AppEnvironment: String {
    case demo
    case prod

    static var current: AppEnvironment {
        guard let value = ProcessInfo.processInfo.environment["APP_ENV"]?.lowercased() else {
            return .demo
        }
        return AppEnvironment(rawValue: value) ?? .demo
    }
}

struct APIConfig {
    static var baseURL: String {
        switch AppEnvironment.current {
        case .demo:
            return "https://demo.fushigi.bunkbed.tech"
        case .prod:
            return "https://fushigi.bunkbed.tech"
        }
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
        redirectURL = "\(APIConfig.baseURL)/api/oauth2-redirect"
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
