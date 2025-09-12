//
//  UserModel.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

import Foundation
import SwiftData

// MARK: - User Remote

/// User model for remote PocketBase database
struct UserRemote: Codable {
    let id: String
    let email: String
    let name: String
    let created: Date
    let updated: Date
}

// MARK: - User Local

/// User model for local SwiftData storage
@Model
final class UserLocal {
    @Attribute var id: String = UUID().uuidString
    var email: String = ""
    var name: String = ""
    var created: Date = Date()
    var updated: Date = Date()

    // Convenience init for when making an ID in SwiftDataland
    init(id: UUID = UUID(),
         email: String = "",
         name: String = "",
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id.uuidString
        self.email = email
        self.name = name
        self.created = created
        self.updated = updated
    }

    // Convenience init for ID coming from PocketBaseLand
    init(id: String = UUID().uuidString,
         email: String = "",
         name: String = "",
         created: Date = Date(),
         updated: Date = Date())
    {
        self.id = id
        self.email = email
        self.name = name
        self.created = created
        self.updated = updated
    }
}
