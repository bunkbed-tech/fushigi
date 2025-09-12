//
//  GrammarModel.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
import SwiftData

// MARK: - Grammar Point Create

/// Grammar for model for simple submission to backend
struct GrammarPointCreate: Codable {
    let usage: String
    let meaning: String
    let context: String
    let tags: [String]
    let notes: String
    let nuance: String
    let examples: [Example]
    let user: String
    let language: String
}

// MARK: - Grammar Point Remote

/// Grammar point model for remote PocketBase database
struct GrammarPointRemote: Codable {
    let id: String
    let user: String
    let language: String
    let usage: String
    let meaning: String
    let context: String
    let tags: [String]
    let notes: String
    let nuance: String
    let examples: [Example]
    let created: Date
    let updated: Date

    // Optional expand field for when ?expand=user,language is used on the route
    let expand: ExpandedRelations?

    struct ExpandedRelations: Codable {
        let user: UserRemote?
        let language: ExpandedLanguage? // Full language object if expanded
    }

    struct ExpandedLanguage: Codable {
        // More in depth model not necessary yet
        let id: String
        let name: String
        let created: Date
        let updated: Date
    }

    init(from model: GrammarPointLocal) {
        id = model.id
        user = model.user ?? ""
        language = model.language
        usage = model.usage
        meaning = model.meaning
        context = model.context
        tags = model.tags
        notes = model.notes
        nuance = model.nuance
        examples = model.examples
        created = model.created
        updated = model.updated
        expand = nil // Not necessary locally
    }
}

// MARK: - Grammar Point Local

/// Grammar point model for local SwiftData storage
@Model
final class GrammarPointLocal {
    @Attribute var id: String = UUID().uuidString
    var user: String?
    var language: String = ""
    var context: String = ""
    var usage: String = ""
    var meaning: String = ""
    var tags: [String] = []
    var notes: String = ""
    var nuance: String = ""
    var examples: [Example] = []
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(id: UUID = UUID(),
         user: String? = nil,
         language: String = "",
         context: String = "",
         usage: String = "",
         meaning: String = "",
         tags: [String] = [],
         notes: String = "",
         nuance: String = "",
         examples: [Example] = [],
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id.uuidString
        self.user = user
        self.language = language
        self.context = context
        self.usage = usage
        self.meaning = meaning
        self.tags = tags
        self.notes = notes
        self.nuance = nuance
        self.examples = examples
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(id: String = "",
         user: String? = nil,
         language: String = "",
         context: String = "",
         usage: String = "",
         meaning: String = "",
         tags: [String] = [],
         notes: String = "",
         nuance: String = "",
         examples: [Example] = [],
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id
        self.user = user
        self.language = language
        self.context = context
        self.usage = usage
        self.meaning = meaning
        self.tags = tags
        self.notes = notes
        self.nuance = nuance
        self.examples = examples
        self.created = created
        self.updated = updated
    }
}

// MARK: - Codable Helpers

/// JSON value stored in database for Examples
struct Example: Codable {
    let japanese: String
    let english: String
}
