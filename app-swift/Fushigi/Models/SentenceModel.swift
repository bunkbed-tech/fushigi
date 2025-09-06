//
//  SentenceModel.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/13.
//

import Foundation
import SwiftData

/// Sentence for model for simple submission to backend
struct SentenceCreate: Codable {
    let content: String
    let user: String
    let journalEntry: String
    let grammar: String
}

/// Sentence model for remote Pocketbase database
struct SentenceRemote: Codable {
    let id: String
    let user: String
    let journalEntry: String
    let grammar: String
    let content: String
    let created: Date
    let updated: Date

    // Optional expand field for when ?expand=user,journal_entry,gramamr is used on the route
    let expand: ExpandedRelations?

    struct ExpandedRelations: Codable {
        let user: UserRemote?
        let journalEntry: JournalEntryRemote?
        let grammar: GrammarPointRemote?
    }

    init(from model: SentenceLocal) {
        id = model.id
        user = model.user
        journalEntry = model.journalEntry
        grammar = model.grammar
        content = model.content
        created = model.created
        updated = model.updated
        expand = nil // Not necessary locally
    }

    enum CodingKeys: String, CodingKey {
        case id, user, grammar, content, created, updated, expand
        case journalEntry = "journal_entry"
    }
}

/// Sentence model for local SwiftData storage
@Model
final class SentenceLocal {
    @Attribute var id: String = UUID().uuidString
    var user: String = UUID().uuidString
    var journalEntry: String = UUID().uuidString
    var grammar: String = UUID().uuidString
    var content: String = ""
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(
        id: UUID = UUID(),
        user: UUID = UUID(),
        journalEntry: UUID = UUID(),
        grammar: UUID = UUID(),
        content: String = "",
        created: Date = Date(),
        updated: Date = Date(),
    ) {
        self.id = id.uuidString
        self.user = user.uuidString
        self.journalEntry = journalEntry.uuidString
        self.grammar = grammar.uuidString
        self.content = content
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(
        id: String = "",
        user: String = "",
        journalEntry: String = "",
        grammar: String = "",
        content: String = "",
        created: Date = Date(),
        updated: Date = Date(),
    ) {
        self.id = id
        self.user = user
        self.journalEntry = journalEntry
        self.grammar = grammar
        self.content = content
        self.created = created
        self.updated = updated
    }
}
