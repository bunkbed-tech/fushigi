//
//  GrammarPoint.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation
import SwiftData

// MARK: - Remote Postgres model

/// Grammar point model for remote PostgreSQL database
struct GrammarPointRemote: Identifiable, Decodable, Hashable, Sendable {
    let id: UUID
    let context: String
    let usage: String
    let meaning: String
    let tags: [String]

    init(from model: GrammarPointLocal) {
        id = model.id
        context = model.context
        usage = model.usage
        meaning = model.meaning
        tags = model.tags
    }
}

// MARK: - Local/iCloud model

/// Grammar point model for local SwiftData storage
@Model
final class GrammarPointLocal {
    @Attribute(.unique) var id: UUID
    var context: String
    var usage: String
    var meaning: String
    var tags: [String]

    init(id: UUID, context: String, usage: String, meaning: String, tags: [String] = []) {
        self.id = id
        self.context = context
        self.usage = usage
        self.meaning = meaning
        self.tags = tags
    }
}
