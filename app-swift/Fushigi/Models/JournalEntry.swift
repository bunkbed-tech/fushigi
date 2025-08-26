//
//  JournalEntry.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
import SwiftData

// MARK: - Remote Postgres models

/// Journal entry for model for simple submission to backend
struct JournalEntryCreate: Codable {
    let title: String
    let content: String
    let `private`: Bool
}

/// Response containing new entry ID for displaying success messages
struct JournalEntryResponseID: Decodable {
    let id: UUID
}

/// Journal entry model for remote PostgreSQL database
struct JournalEntryRemote: Identifiable, Decodable {
    let id: UUID
    let title: String
    let content: String
    let `private`: Bool
    let createdAt: Date
    // let userId: UUID
    // let grammarPoints: [String]
    // let aiFeedback: String

    enum CodingKeys: String, CodingKey {
        case id, title, content, `private`
        case createdAt = "created_at"
        // case userId = "user_id"
    }
}

// MARK: - Local/iCloud model

/// Grammar point model for local SwiftData storage
@Model
final class JournalEntryLocal {
    @Attribute var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var `private`: Bool = false
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String = "", content: String = "", private: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.private = `private`
        self.createdAt = createdAt
    }
}
