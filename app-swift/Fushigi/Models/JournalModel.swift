//
//  JournalModel.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
import SwiftData

// MARK: - Journal Entry Create

/// Journal entry for model for simple submission to backend
struct JournalEntryCreate: Codable {
    let title: String
    let content: String
    let isPrivate: Bool
    let user: String

    enum CodingKeys: String, CodingKey {
        case title, content, user
        case isPrivate = "is_private"
    }
}

// MARK: - Journal Entry Remote

/// Journal entry model for remote PocketBase database
struct JournalEntryRemote: Codable {
    let id: String
    let user: String
    let title: String
    let content: String
    let isPrivate: Bool
    let created: Date
    let updated: Date

    // Optional expand field for when ?expand=user is used on the route
    let expand: ExpandedRelations?

    struct ExpandedRelations: Codable {
        let user: ExpandedUser? // Full user object if expanded
    }

    struct ExpandedUser: Codable {
        // More in depth model not necessary because not stored on device
        let id: String
        let email: String
        let name: String
        let created: Date
        let updated: Date
    }

    enum CodingKeys: String, CodingKey {
        case id, user, title, content, created, updated, expand
        case isPrivate = "is_private"
    }

    init(from model: JournalEntryLocal) {
        id = model.id
        user = model.user
        title = model.title
        content = model.content
        isPrivate = model.isPrivate
        created = model.created
        updated = model.updated
        expand = nil // Not necessary locally
    }
}

// MARK: - Journal Entry Local

/// Journal entry model for local SwiftData storage
@Model
final class JournalEntryLocal {
    @Attribute var id: String = UUID().uuidString
    var user: String = ""
    var title: String = ""
    var content: String = ""
    var isPrivate: Bool = false
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(
        id: UUID = UUID(),
        user: String = "",
        title: String = "",
        content: String = "",
        isPrivate: Bool = false,
        created: Date = Date(),
        updated: Date = Date(),
    ) {
        self.id = id.uuidString
        self.user = user
        self.title = title
        self.content = content
        self.isPrivate = isPrivate
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(
        id: String,
        user: String,
        title: String,
        content: String,
        isPrivate: Bool,
        created: Date,
        updated: Date,
    ) {
        self.id = id
        self.user = user
        self.title = title
        self.content = content
        self.isPrivate = isPrivate
        self.created = created
        self.updated = updated
    }
}
