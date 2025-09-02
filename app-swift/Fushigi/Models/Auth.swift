//
//  Auth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
import SwiftData

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

enum APIConfig {
    static var baseURL: String {
        switch AppEnvironment.current {
        case .demo:
            "https://demo.fushigi.bunkbed.tech"
        case .prod:
            "https://fushigi.bunkbed.tech"
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

enum AuthError: Error, LocalizedError {
    case invalidCredentials(String, underlying: Error? = nil)
    case networkError(String, underlying: Error? = nil)
    case serverError(String, underlying: Error? = nil)
    case decodingError(String, underlying: Error? = nil)
    case tokenStorageError(String, underlying: Error? = nil)

    var errorDescription: String? {
        switch self {
        case let .invalidCredentials(msg, underlying),
             let .networkError(msg, underlying),
             let .serverError(msg, underlying),
             let .decodingError(msg, underlying),
             let .tokenStorageError(msg, underlying):
            "\(msg)" + (underlying.map { " (\($0))" } ?? "")
        }
    }
}

@Model
final class User {
    @Attribute var id: String = UUID().uuidString
    var email: String = ""
    var name: String = ""
    var created: Date = Date()
    var updated: Date = Date()

    init(id: UUID = UUID(),
         email: String = "",
         name: String = "",
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id.uuidString
        self.email = email
        self.name = name
        self.created = created
        self.updated = updated
    }
}
