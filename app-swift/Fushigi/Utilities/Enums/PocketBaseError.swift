//
//  PocketBaseError.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

import Foundation

enum PocketBaseError: Error, LocalizedError {
    case invalidCredentials(String, underlying: Error? = nil)
    case tokenStorageError(String, underlying: Error? = nil)
    case networkError(String, underlying: Error? = nil)
    case serverError(String, underlying: Error? = nil)
    case decodingError(String, underlying: Error? = nil)

    var errorDescription: String? {
        switch self {
        case let .invalidCredentials(msg, underlying),
             let .tokenStorageError(msg, underlying),
             let .networkError(msg, underlying),
             let .serverError(msg, underlying),
             let .decodingError(msg, underlying):
            "\(msg)" + (underlying.map { " (\($0))" } ?? "")
        }
    }
}
