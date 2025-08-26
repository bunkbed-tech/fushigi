//
//  SentenceAPI.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import Foundation

/// Fetch all grammar points from FastAPI backend
@MainActor
func fetchSentences() async -> Result<[SentenceRemote], Error> {
    guard let url = URL(string: "http://192.168.11.5:8000/api/sentences") else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let points = try JSONDecoder().decode([SentenceRemote].self, from: data)
        return .success(points)
    } catch {
        return .failure(error)
    }
}
