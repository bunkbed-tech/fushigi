//
//  AuthenticationUnitTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi
import Testing

// MARK: - Authentication Unit Tests

struct AuthenticationUnitTests {
    @Test func authRequestEncodesCorrectly() throws {
        // Setup
        let request = AuthRequest(
            provider: "apple",
            identityToken: "test-token",
            providerUserId: "test-user",
            email: "test@example.com",
        )

        // Run
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(AuthRequest.self, from: data)

        // Verify
        #expect(decoded.provider == "apple")
        #expect(decoded.identityToken == "test-token")
        #expect(decoded.providerUserId == "test-user")
        #expect(decoded.email == "test@example.com")
    }
}
