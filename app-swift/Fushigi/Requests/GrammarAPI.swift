//
//  GrammarAPI.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import Foundation

/// Fetch all grammar points from FastAPI backend
@MainActor
func fetchGrammarPoints() async -> Result<[GrammarPointRemote], Error> {
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
