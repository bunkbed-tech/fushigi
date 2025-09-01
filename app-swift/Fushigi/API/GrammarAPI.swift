//
//  GrammarAPI.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation

/// Define protocol that API must satisfy to make it more testable
protocol RemoteGrammarDataServiceProtocol {
    func fetchGrammarPoints() async -> Result<[GrammarPointRemote], Error>
}

/// True API declaration that calls fetchGrammarOnApi()
class ProductionRemoteGrammarDataService: RemoteGrammarDataServiceProtocol {
    func fetchGrammarPoints() async -> Result<[GrammarPointRemote], Error> {
        await fetchGrammarOnAPI()
    }
}

/// Mock API declaration that returns preformed GrammarPointRemote or error message
class MockRemoteGrammarDataService: RemoteGrammarDataServiceProtocol {
    var result: Result<[GrammarPointRemote], Error> = .success([])

    func fetchGrammarPoints() async -> Result<[GrammarPointRemote], Error> {
        result
    }

    /// Sets the mock to return an error result
    func withError(_ error: Error) -> Self {
        result = .failure(error)
        return self
    }

    /// Sets the mock to return a successful result
    func withSuccess(_ points: [GrammarPointRemote]) -> Self {
        result = .success(points)
        return self
    }
}

/// Fetch all grammar points from FastAPI backend
@MainActor
func fetchGrammarOnAPI() async -> Result<[GrammarPointRemote], Error> {
    guard let url = URL(string: "http://192.168.11.5:8000/api/grammar") else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let points = try JSONDecoder().decode([GrammarPointRemote].self, from: data)
        return .success(points)
    } catch {
        return .failure(error)
    }
}
