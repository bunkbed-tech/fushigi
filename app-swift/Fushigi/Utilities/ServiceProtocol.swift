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

struct BulkResponse: Decodable {
    let responses: [DefaultResponse]
}

protocol RemoteServiceProtocol {
    associatedtype Item: Codable
    associatedtype Create: Encodable

    func fetchItems() async -> Result<PaginatedResponse<Item>, Error>
    func fetchAllItems() async -> Result<[Item], Error>
    func postItem(_ newItem: Create) async -> Result<String, Error>
    func postBulkItems(_ items: [Create]) async -> Result<[String], Error>
}

/// Generic production CRUD service
class ProdRemoteService<Item: Codable, Create: Encodable>: RemoteServiceProtocol {
    private let endpoint: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        endpoint: String,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
    ) {
        self.endpoint = endpoint
        self.decoder = decoder
        self.encoder = encoder
    }

    /// First page fetch for convenience and protocol conformance
    func fetchItems() async -> Result<PaginatedResponse<Item>, Error> {
        await fetchItems(1)
    }

    /// Full Pagination Fetch
    func fetchAllItems() async -> Result<[Item], Error> {
        var allItems: [Item] = []
        var page = 1

        print("LOG: Starting full sync for \(endpoint)...")

        while true {
            print("LOG: Fetching page \(page) of \(endpoint)...")

            let pageResult = await fetchItems(page)

            switch pageResult {
            case let .success(response):
                allItems.append(contentsOf: response.items)
                print("LOG: Fetched \(response.items.count) items, total: \(allItems.count)")

                // Check if we're done
                if page >= response.totalPages {
                    print("LOG: Completed sync for \(endpoint): \(allItems.count) items total")
                    return .success(allItems)
                }

                page += 1

            case let .failure(error):
                print("ERROR: Failed to fetch page \(page) of \(endpoint): \(error)")
                return .failure(error)
            }
        }
    }

    /// Single Page Fetch
    func fetchItems(_ page: Int, perPage: Int = 100) async -> Result<PaginatedResponse<Item>, Error> {
        guard let url =
            URL(string: "\(APIConfig.baseURL)/api/collections/\(endpoint)/records?page=\(page)&perPage=\(perPage)")
        else {
            return .failure(URLError(.badURL))
        }

        do {
            var request = URLRequest(url: url)
            if let token = KeychainHelper.shared.load(forKey: "pbToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try decoder.decode(PaginatedResponse<Item>.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    /// Single Item Post
    func postItem(_ newItem: Create) async -> Result<String, Error> {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/collections/\(endpoint)/records") else {
            return .failure(URLError(.badURL))
        }

        do {
            var request = URLRequest(url: url)
            if let token = KeychainHelper.shared.load(forKey: "pbToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(newItem)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(DefaultResponse.self, from: data)
            return .success(response.id)
        } catch {
            return .failure(error)
        }
    }

    /// Bulk Item Post
    func postBulkItems(_ items: [Create]) async -> Result<[String], Error> {
        // Convert items to dictionaries
        let itemDicts: [[String: Any]]
        do {
            let data = try encoder.encode(items)
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return .failure(URLError(.cannotParseResponse))
            }
            itemDicts = jsonArray
        } catch {
            return .failure(error)
        }

        // Build list of requests for each
        let requests = itemDicts.map { item in
            [
                "method": "POST",
                "url": "/api/collections/\(endpoint)/records",
                "body": item,
            ] as [String: Any]
        }
        let batchData = ["requests": requests]

        // Continue with standard postItem format but on the batch API
        guard let url = URL(string: "\(APIConfig.baseURL)/api/batch") else {
            return .failure(URLError(.badURL))
        }

        do {
            var request = URLRequest(url: url)
            if let token = KeychainHelper.shared.load(forKey: "pbToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            request.httpBody = try JSONSerialization.data(withJSONObject: batchData)

            let (data, _) = try await URLSession.shared.data(for: request)

            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responses = jsonObject["responses"] as? [[String: Any]]
            else {
                return .failure(URLError(.cannotParseResponse))
            }

            let createdIDs = responses.compactMap { response -> String? in
                return response["id"] as? String
            }

            return .success(createdIDs)
        } catch {
            return .failure(error)
        }
    }
}

/// Generic mock CRUD service
class MockRemoteService<Item: Codable, Create: Encodable>: RemoteServiceProtocol {
    enum MockNotConfigured: Error { case fetch, fetchAll, post, postBulk }

    private var fetchResult: Result<PaginatedResponse<Item>, Error> = .failure(MockNotConfigured.fetch)
    private var fetchAllResult: Result<[Item], Error> = .failure(MockNotConfigured.fetchAll)
    private var postResult: Result<String, Error> = .failure(MockNotConfigured.post)
    private var postBulkResult: Result<[String], Error> = .failure(MockNotConfigured.postBulk)

    func fetchItems() async -> Result<PaginatedResponse<Item>, Error> {
        fetchResult
    }

    func fetchAllItems() async -> Result<[Item], Error> {
        fetchAllResult
    }

    func postItem(_: Create) async -> Result<String, Error> {
        postResult
    }

    func postBulkItems(_: [Create]) async -> Result<[String], Error> {
        postBulkResult
    }

    // Configuration methods
    func withFetchError(_ error: Error) -> Self {
        fetchResult = .failure(error)
        return self
    }

    func withFetchSuccess(_ items: PaginatedResponse<Item>) -> Self {
        fetchResult = .success(items)
        return self
    }

    func withFetchAllSuccess(_ items: [Item]) -> Self {
        fetchAllResult = .success(items)
        return self
    }

    func withFetchAllError(_ error: Error) -> Self {
        fetchAllResult = .failure(error)
        return self
    }

    func withPostError(_ error: Error) -> Self {
        postResult = .failure(error)
        return self
    }

    func withPostSuccess(_ id: String) -> Self {
        postResult = .success(id)
        return self
    }

    func withPostBulkError(_ error: Error) -> Self {
        postBulkResult = .failure(error)
        return self
    }

    func withPostBulkSuccess(_ ids: [String]) -> Self {
        postBulkResult = .success(ids)
        return self
    }
}
