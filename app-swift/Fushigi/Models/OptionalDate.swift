//
//  OptionalDate.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/09.
//

import Foundation

// MARK: - Optional Date

/// Required since PocketBase returns nullable dates as empty strings
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
