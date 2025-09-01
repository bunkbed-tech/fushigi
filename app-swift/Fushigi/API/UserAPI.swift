//
//  UserAPI.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/26.
//

import Foundation

@MainActor
func postAuthRequest(_ login: AuthRequest) async -> Result<AuthResponse, Error> {
    let endpoint: String
    switch login.provider.lowercased() {
    case "apple":
        endpoint = "https://demo.fushigi.bunkbed.tech/api/collections/users/auth-with-oauth2"
    case "email":
        endpoint = "https://demo.fushigi.bunkbed.tech/api/collections/users/auth-with-password"
    default:
        return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported provider"]))
    }

    guard let url = URL(string: endpoint) else {
        return .failure(URLError(.badURL))
    }

    do {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(login)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status for auth endpoints
        if let httpResponse = response as? HTTPURLResponse,
           !(200 ... 299).contains(httpResponse.statusCode)
        {
            return .failure(URLError(.badServerResponse))
        }

        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        return .success(auth)
    } catch let jsonError as DecodingError {
        return .failure(
            NSError(
                domain: "",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "\(jsonError)"],
            ),
        )
    } catch {
        return .failure(error)
    }
}
