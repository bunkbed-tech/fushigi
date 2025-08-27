//
//  User.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/26.
//

import Foundation

/// Represents authenticated user session
@MainActor
class UserSession: ObservableObject {
    /// UUID in postgres
    @Published var id: UUID

    /// Apple for users, hardcoded for testing, left open for future auth methods
    @Published var provider: String

    /// Id provided by authorization system
    @Published var providerUserId: String

    /// Optional email reference for currently undecided future social features
    @Published var email: String?

    init(id: UUID, provider: String, providerUserId: String, email: String? = nil) {
        self.id = id
        self.provider = provider
        self.providerUserId = providerUserId
        self.email = email
    }
}

/// Authorized users from the remote PostgreSQL database
struct UserRemote: Decodable {
    /// UUID in postgres
    let id: UUID

    /// Apple for users, hardcoded for testing, left open for future auth methods
    let provider: String

    /// Id provided by authorization system
    let providerUserId: String

    /// Optional email reference for currently undecided future social features
    let email: String?

    /// User creation date
    let createdAt: Date

    /// Last user edit date
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, provider, email
        case providerUserId = "provider_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
