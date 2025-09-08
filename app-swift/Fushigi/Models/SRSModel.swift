//
//  SRSModel.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/05.
//

import Foundation
import SwiftData

/// Required since Pocketbase returns nullable dates as empty strings
@propertyWrapper
struct OptionalDate {
    private var date: Date

    init(wrappedValue: Date?) {
        date = wrappedValue ?? Date.distantPast
    }

    var wrappedValue: Date? {
        get { date == Date.distantPast ? nil : date }
        set { date = newValue ?? Date.distantPast }
    }
}

/// Tell JSON decoder how to deal with OptionalDate type
extension OptionalDate: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        date = try container.decode(Date.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date)
    }
}

/// SRS Record model for simple submission to backend
struct SRSRecordCreate: Codable {
    let user: String
    let grammar: String
    let easeFactor: Double
    let intervalDays: Double
    let repetition: Double

    enum CodingKeys: String, CodingKey {
        case user, grammar, repetition
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
    }
}

/// SRS Record model for remote Pocketbase database
struct SRSRecordRemote: Codable {
    let id: String
    let user: String
    let grammar: String
    let easeFactor: Double
    let intervalDays: Double
    let repetition: Double
    @OptionalDate var lastReviewed: Date?
    let dueDate: Date
    let created: Date
    let updated: Date

    // Optional expand field for when ?expand=user,grammar is used on the route
    let expand: ExpandedRelations?

    struct ExpandedRelations: Codable {
        let user: UserRemote?
        let grammar: GrammarPointRemote?
    }

    init(from model: SRSRecordLocal) {
        id = model.id
        user = model.user
        grammar = model.grammar
        easeFactor = model.easeFactor
        intervalDays = model.intervalDays
        repetition = model.repetition
        dueDate = model.dueDate
        created = model.created
        updated = model.updated
        expand = nil
        _lastReviewed = OptionalDate(wrappedValue: model.lastReviewed)
    }

    enum CodingKeys: String, CodingKey {
        case id, user, grammar, repetition, created, updated, expand
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case lastReviewed = "last_reviewed"
        case dueDate = "due_date"
    }
}

/// SRS Record model for local SwiftData storage
@Model
final class SRSRecordLocal {
    @Attribute var id: String = UUID().uuidString
    var user: String = UUID().uuidString
    var grammar: String = UUID().uuidString
    var easeFactor: Double = 2.5
    var intervalDays: Double = 1.0
    var repetition: Double = 0.0
    var lastReviewed: Date?
    var dueDate: Date = Date()
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(
        id: UUID = UUID(),
        user: UUID = UUID(),
        grammar: UUID = UUID(),
        easeFactor: Double = 2.5,
        intervalDays: Double = 1.0,
        repetition: Double = 0.0,
        lastReviewed: Date? = nil,
        dueDate: Date = Date(),
        created: Date = Date(),
        updated: Date = Date(),
    ) {
        self.id = id.uuidString
        self.user = user.uuidString
        self.grammar = grammar.uuidString
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetition = repetition
        self.lastReviewed = lastReviewed
        self.dueDate = dueDate
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(
        id: String = "",
        user: String = "",
        grammar: String = "",
        easeFactor: Double = 2.5,
        intervalDays: Double = 1.0,
        repetition: Double = 0.0,
        lastReviewed: Date? = nil,
        dueDate: Date = Date(),
        created: Date = Date(),
        updated: Date = Date(),
    ) {
        self.id = id
        self.user = user
        self.grammar = grammar
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetition = repetition
        self.lastReviewed = lastReviewed
        self.dueDate = dueDate
        self.created = created
        self.updated = updated
    }
}
