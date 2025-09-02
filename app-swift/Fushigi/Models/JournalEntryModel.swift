//
//  JournalEntryModel.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
import SwiftData

/// Journal entry for model for simple submission to backend
struct JournalEntryCreate: Codable {
    let title: String
    let content: String
    let `private`: Bool
}

/// Journal entry model for remote PostgreSQL database
struct JournalEntryRemote: Identifiable, Decodable, Encodable {
    let id: UUID
    let title: String
    let content: String
    let `private`: Bool
    let createdAt: Date
}

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
