//
//  LoginPage.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import AuthenticationServices
import SwiftUI

// MARK: - Login Page

/// Simple barebones login page stub, eventually gate data load behind this and authorization
struct LoginPage: View {
    /// Placeholder for logging in via email, eventually want auth
    @State private var email = "tester@example.com"

    /// Placeholder for logging in with password, eventually want auth
    @State private var password = "test123"

    /// Flag to show loading animation during user authentication
    @State private var isAuthenticating = false

    /// Error, incorrect login, etc type error messages for user feedback
    @State private var errorMessage: String?

    /// Callback when user successfully logs in
    let onLogin: (UserSession) -> Void

    // MARK: - Main View

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: UIConstants.Spacing.content) {
                Spacer()

                VStack(spacing: UIConstants.Spacing.section) {
                    Image("Splash-AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIConstants.Sizing.bigIcons, height: UIConstants.Sizing.bigIcons)

                    VStack(spacing: UIConstants.Spacing.row) {
                        Text("Master output through targeted journaling.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: UIConstants.Spacing.content) {
                    // Apple Sign In Button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .frame(width: 280, height: 45)

                    // OR divider
                    HStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Temporary test login form
                    VStack(spacing: UIConstants.Spacing.section) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                        #if os(iOS)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        #endif
                            .frame(width: 280, height: 45)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                            .frame(width: 280, height: 45)
                    }

                    Button {
                        authenticateWithTestCredentials()
                    } label: {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isAuthenticating ? "Signing in..." : "Sign In (Test)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || isAuthenticating)

                    // Show error message if exists
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, UIConstants.Padding.largeIndent)

                Spacer()

                // Footer
                VStack(spacing: UIConstants.Spacing.row) {
                    Text("Don't have an account?")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Sign Up") {
                        // TODO: Navigate to sign up
                        print("TODO: Create sign up flow.")
                    }
                    .font(.caption)
                }
                .padding(.bottom, UIConstants.Padding.largeIndent)
            }
        }
        .background {
            LinearGradient(
                colors: [.mint.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Actions

    /// Handle Apple Sign-In authentication
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isAuthenticating = true

                print("LOG: Apple ID: \(credential.user)")
                print("LOG: Email: \(credential.email ?? "No email")")

                Task {
                    await verifyWithBackend(
                        identityToken: credential.identityToken,
                        user: credential.user,
                        email: credential.email,
                    )
                }
                isAuthenticating = false
            }
        case let .failure(error):
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            print("Apple Sign-In error: \(error)")
        }
    }

    /// Handle test credentials authentication
    private func authenticateWithTestCredentials() {
        isAuthenticating = true
        errorMessage = nil

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Check against hardcoded test user
            if email == "tester@example.com", password == "test123" {
                let testSession = UserSession(
                    id: UUID(uuidString: "431a6bca-0e1b-4820-96cc-8f63b32fdcaf")!,
                    provider: "hardcoded",
                    providerUserId: "tester123",
                    email: "tester@example.com",
                )
                onLogin(testSession)
            } else {
                errorMessage = "Invalid credentials. Use 'tester@example.com' and 'test123'"
            }
            isAuthenticating = false
        }
    }

    private func verifyWithBackend(identityToken: Data?, user: String, email: String?) async {
        guard let identityToken else {
            await MainActor.run {
                errorMessage = "Missing identity token"
                isAuthenticating = false
            }
            return
        }

        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                errorMessage = "Invalid token format"
                isAuthenticating = false
            }
            return
        }

        let request = AuthRequest(
            provider: "apple",
            identityToken: tokenString,
            providerUserId: user,
            email: email,
        )

        let result = await postAuthRequest(request)

        await MainActor.run {
            switch result {
            case let .success(response):
                let session = UserSession(
                    id: response.user.id,
                    provider: response.user.provider,
                    providerUserId: response.user.providerUserId,
                    email: response.user.email,
                )
                isAuthenticating = false
                onLogin(session)

            case let .failure(error):
                errorMessage = "Authentication failed: \(error.localizedDescription)"
                isAuthenticating = false
            }
        }
    }
}

#Preview("Login Page") {
    LoginPage { session in
        print("Logged in as: \(session.providerUserId)")
    }
}
