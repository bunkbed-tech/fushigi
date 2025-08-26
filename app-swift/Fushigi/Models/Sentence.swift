//
//  Sentence.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/13.
//

import Foundation
import SwiftData

// MARK: - Remote Postgres model

/// Sentence model for remote PostgreSQL database
struct SentenceRemote: Identifiable, Decodable, Hashable, Sendable {
    let id: UUID
    let journalEntryId: UUID
    let grammarId: UUID
    let content: String
    let createdAt: Date

    init(from model: SentenceLocal) {
        id = model.id
        journalEntryId = model.journalEntryId
        grammarId = model.grammarId
        content = model.content
        createdAt = model.createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, content
        case journalEntryId = "journal_entry_id"
        case grammarId = "grammar_id"
        case createdAt = "created_at"
    }
}

// MARK: - Local/iCloud model

/// Sentence model for local SwiftData storage
@Model
final class SentenceLocal {
    @Attribute var id: UUID = UUID()
    var journalEntryId: UUID = UUID()
    var grammarId: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        journalEntryId: UUID = UUID(),
        grammarId: UUID = UUID(),
        content: String = "",
        createdAt: Date = Date(),
    ) {
        self.id = id
        self.journalEntryId = journalEntryId
        self.grammarId = grammarId
        self.content = content
        self.createdAt = createdAt
    }
}
