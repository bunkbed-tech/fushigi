//
//  PaginatedResponse.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

/// Return structure from Pocketbase has the following wrapper
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
}
