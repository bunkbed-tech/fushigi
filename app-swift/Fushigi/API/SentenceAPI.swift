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
    guard let url = URL(string: "https://demo.fushigi.bunkbed.tech/api/collections/sentences") else {
        return .failure(URLError(.badURL))
    }

    do {
        var request = URLRequest(url: url)
        if let token = KeychainHelper.shared.load(forKey: "pbToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let points = try JSONDecoder().decode([SentenceRemote].self, from: data)
        return .success(points)
    } catch {
        return .failure(error)
    }
}
