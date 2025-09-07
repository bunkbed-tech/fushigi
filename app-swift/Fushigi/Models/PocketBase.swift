//
//  PocketBase.swift
//  Fushigi
//
//  Created by Tristan Schrader on 9/5/25.
//

import Foundation

struct PocketBaseErrorResponseData: Decodable {
    let code: String
    let message: String
}

struct PocketBaseErrorResponse: Decodable {
    let status: Int
    let message: String
    let data: [String: PocketBaseErrorResponseData]
}

struct PocketBaseCreateRecordResponse: Decodable {
    let collectionId: String
    let collectionName: String
    let id: String
    let updated: Date
    let created: Date
}
