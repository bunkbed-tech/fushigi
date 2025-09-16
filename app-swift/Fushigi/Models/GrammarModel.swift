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
    let context: [String]
    let level: String
    let variant: String
    let notes: String
    let examples: [Example]
    let forms: [String: String]
    let tags: [String]
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
    let context: [String]
    let level: String
    let variant: String
    let notes: String
    let examples: [Example]
    let forms: [String: String]
    let tags: [String]
    let created: Date
    let updated: Date

    // Optional expand field for when ?expand=user,language is used on the route
    let expand: ExpandedRelations?

    struct ExpandedRelations: Codable {
        let user: UserRemote?
        let language: ExpandedLanguage?
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
        user = model.user
        language = model.language
        usage = model.usage
        meaning = model.meaning
        context = model.context
        level = model.level
        variant = model.variant
        notes = model.notes
        examples = model.examples
        forms = model.forms
        tags = model.tags
        created = model.created
        updated = model.updated
        expand = nil
    }
}

// MARK: - Grammar Point Local

/// Grammar point model for local SwiftData storage
@Model
final class GrammarPointLocal {
    @Attribute var id: String = UUID().uuidString
    var user: String = ""
    var language: String = ""
    var context: [String] = []
    var usage: String = ""
    var meaning: String = ""
    var level: String = ""
    var variant: String = ""
    var notes: String = ""
    var examples: [Example] = []
    var forms: [String: String] = [:]
    var tags: [String] = []
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(id: UUID = UUID(),
         user: String = "",
         language: String = "",
         context: [String] = [],
         usage: String = "",
         meaning: String = "",
         level: String = "",
         variant: String = "",
         notes: String = "",
         examples: [Example] = [],
         forms: [String: String] = [:],
         tags: [String] = [],
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id.uuidString
        self.user = user
        self.language = language
        self.context = context
        self.usage = usage
        self.meaning = meaning
        self.level = level
        self.variant = variant
        self.notes = notes
        self.examples = examples
        self.forms = forms
        self.tags = tags
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(id: String = "",
         user: String = "",
         language: String = "",
         context: [String] = [],
         usage: String = "",
         meaning: String = "",
         level: String = "",
         variant: String = "",
         notes: String = "",
         examples: [Example] = [],
         forms: [String: String] = [:],
         tags: [String] = [],
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id
        self.user = user
        self.language = language
        self.context = context
        self.usage = usage
        self.meaning = meaning
        self.level = level
        self.variant = variant
        self.notes = notes
        self.examples = examples
        self.forms = forms
        self.tags = tags
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
