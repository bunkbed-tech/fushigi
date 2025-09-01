//
//  Auth.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

/// Represents authentication object required to perform auth
struct AuthRequest: Codable {
    /// Apple for users, hardcoded for testing, left open for future auth methods
    let provider: String

    /// JWT provided by authorization system
    let identityToken: String

    /// Id provided by authorization system
    let providerUserId: String

    /// Optional email reference for currently undecided future social features
    let email: String?

    private enum CodingKeys: String, CodingKey {
        case provider, email
        case identityToken = "identity_token"
        case providerUserId = "provider_user_id"
    }
}

/// Authorization response from PostgreSQL database
struct AuthResponse: Decodable {
    /// Object corresponding to entire user
    let user: UserRemote

    /// JWT provided by authorization system
    let token: String
}
