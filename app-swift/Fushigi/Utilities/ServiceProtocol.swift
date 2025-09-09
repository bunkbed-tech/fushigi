//
//  ServiceProtocol.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/02.
//

import Foundation

// MARK: - Remote Service Protocol

/// CRUD protocol to help make api to PocketBase generic and testable
protocol RemoteServiceProtocol {
    // MARK: - Required Types

    /// Fetch object type
    associatedtype Item: Codable

    /// Post object type
    associatedtype Create: Encodable

    // MARK: - Required Functions

    /// Single item fetch
    func fetchItems() async -> Result<PaginatedResponse<Item>, Error>

    /// Multi item fetch
    func fetchAllItems() async -> Result<[Item], Error>

    /// Single item post
    func postItem(_ newItem: Create) async -> Result<String, Error>

    /// Bulk item post
    func postBulkItems(_ items: [Create]) async -> Result<[String], Error>
}

/// Generic production CRUD service
class ProdRemoteService<Item: Codable, Create: Encodable>: RemoteServiceProtocol {
    // MARK: - Init

    /// Location of PocketBase provided API
    private let endpoint: String

    /// Sometimes custom decoder required to create objects from JSON coming from PocketBase
    private let decoder: JSONDecoder

    /// Sometimes custom encoder required to turn objects in Swift to JSON for posting
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

    // MARK: - Helper Methods

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

            let (data, response) = try await URLSession.shared.data(for: request)
            // DEBUG: Log the actual response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            print("Raw response body: \(String(data: data, encoding: .utf8) ?? "Could not decode data")")

            let fullresponse = try decoder.decode(DefaultResponse.self, from: data)
            return .success(fullresponse.id)
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

// MARK: - Remote Service Protocol

/// Testable generic production CRUD service
class MockRemoteService<Item: Codable, Create: Encodable>: RemoteServiceProtocol {
    // MARK: - Init

    /// Helper enum to display expected failures across API testing
    enum MockNotConfigured: Error { case fetch, fetchAll, post, postBulk }

    /// Mocked fetch result
    private var fetchResult: Result<PaginatedResponse<Item>, Error> = .failure(MockNotConfigured.fetch)

    /// Mocked fetch all result
    private var fetchAllResult: Result<[Item], Error> = .failure(MockNotConfigured.fetchAll)

    /// Mocked post result
    private var postResult: Result<String, Error> = .failure(MockNotConfigured.post)

    /// Mocked bulk post result
    private var postBulkResult: Result<[String], Error> = .failure(MockNotConfigured.postBulk)

    // MARK: - Helper Methods

    /// Mocked single item fetch
    func fetchItems() async -> Result<PaginatedResponse<Item>, Error> {
        fetchResult
    }

    /// Mocked multi item fetch
    func fetchAllItems() async -> Result<[Item], Error> {
        fetchAllResult
    }

    /// Mocked single item post
    func postItem(_: Create) async -> Result<String, Error> {
        postResult
    }

    /// Mocked multi itemi post
    func postBulkItems(_: [Create]) async -> Result<[String], Error> {
        postBulkResult
    }

    /// Mocked single item fetch error message
    func withFetchError(_ error: Error) -> Self {
        fetchResult = .failure(error)
        return self
    }

    /// Mocked single item fetch success message
    func withFetchSuccess(_ items: PaginatedResponse<Item>) -> Self {
        fetchResult = .success(items)
        return self
    }

    /// Mocked multi item fetch success message
    func withFetchAllSuccess(_ items: [Item]) -> Self {
        fetchAllResult = .success(items)
        return self
    }

    /// Mocked multi item fetch error message
    func withFetchAllError(_ error: Error) -> Self {
        fetchAllResult = .failure(error)
        return self
    }

    /// Mocked post error message
    func withPostError(_ error: Error) -> Self {
        postResult = .failure(error)
        return self
    }

    /// Mocked post success message
    func withPostSuccess(_ id: String) -> Self {
        postResult = .success(id)
        return self
    }

    /// Mocked bulk post error message
    func withPostBulkError(_ error: Error) -> Self {
        postBulkResult = .failure(error)
        return self
    }

    /// Mocked bulk post success message
    func withPostBulkSuccess(_ ids: [String]) -> Self {
        postBulkResult = .success(ids)
        return self
    }
}
