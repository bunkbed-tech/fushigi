//
//  ServiceProtocol.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/02.
//

import Foundation

struct DefaultResponse: Decodable {
    let id: String
}

protocol RemoteServiceProtocol {
    associatedtype Item: Decodable
    associatedtype Create: Encodable

    func fetchItems() async -> Result<[Item], Error>
    func postItem(_ newItem: Create) async -> Result<String, Error>
}

/// Generic production CRUD service
class ProdRemoteService<Item: Decodable, Create: Encodable>: RemoteServiceProtocol {
    private let endpoint: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        endpoint: String,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.endpoint = endpoint
        self.decoder = decoder
        self.encoder = encoder
    }

    func fetchItems() async -> Result<[Item], Error> {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/collections/\(endpoint)") else {
            return .failure(URLError(.badURL))
        }

        do {
            var request = URLRequest(url: url)
            if let token = KeychainHelper.shared.load(forKey: "pbToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try decoder.decode([Item].self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    func postItem(_ newItem: Create) async -> Result<String, Error> {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/collections/\(endpoint)") else {
            return .failure(URLError(.badURL))
        }

        do {
            var request = URLRequest(url: url)
            if let token = KeychainHelper.shared.load(forKey: "pbToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            request.httpMethod = "POST"
            request.httpBody = try encoder.encode(newItem)

            let (data, _) = try await URLSession.shared.data(for: request)

            let response = try decoder.decode(DefaultResponse.self, from: data)
            return .success("Saved (ID: \(response.id))")
        } catch {
            return .failure(error)
        }
    }
}

/// Generic mock CRUD service
class MockRemoteService<Item: Decodable, Create: Encodable>: RemoteServiceProtocol {
    private var fetchResult: Result<[Item], Error> = .success([])
    private var postResult: Result<String, Error> = .success("")

    func fetchItems() async -> Result<[Item], Error> {
        fetchResult
    }

    func postItem(_ newItem: Create) async -> Result<String, Error> {
        postResult
    }

    func withFetchError(_ error: Error) -> Self {
        fetchResult = .failure(error)
        return self
    }

    func withFetchSuccess(_ items: [Item]) -> Self {
        fetchResult = .success(items)
        return self
    }

    func withPostError(_ error: Error) -> Self {
        postResult = .failure(error)
        return self
    }

    func withPostSuccess(_ message: String) -> Self {
        postResult = .success(message)
        return self
    }
}
