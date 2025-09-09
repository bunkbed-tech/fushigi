//
//  PocketBaseAPIModel.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation

// MARK: - Authentication

/// PocketBase required format for auth by email
struct EmailAuthRequest: Codable {
    let identity: String
    let password: String
}

/// PocketBase required format for auth by Apple OAuth
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

/// Remote auth record structure coming from PocketBase
struct AuthRecord: Codable {
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

/// Remote auth record wrapper coming from PocketBase
struct AuthResponse: Codable {
    let record: AuthRecord
    let token: String
}

// MARK: - Errors

/// All errors from PocketBase return JSON in this generic format
struct PocketBaseError: Decodable {
    let code: Int
    let message: String
    let data: [String: String]?
}

/// Potential error modes when interacting with PocketBase with user/dev friendly descriptions
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

// MARK: - Standard Responses

/// All successful fetch responses from PocketBase return JSON in this format
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
}

/// Basic response object type coming from PocketBase
struct DefaultResponse: Decodable {
    let id: String
}

/// Bulk response object type coming from PocketBase
struct BulkResponse: Decodable {
    let responses: [DefaultResponse]
}
