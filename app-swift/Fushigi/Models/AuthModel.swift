//
//  AuthModel.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation

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

struct AuthResponse: Codable {
    let record: AuthRecord
    let token: String
}

struct PocketBaseError: Decodable {
    let code: Int
    let message: String
    let data: [String: String]?
}
