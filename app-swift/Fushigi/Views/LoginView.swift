//
//  LoginView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import AuthenticationServices
import SwiftUI

/// Displays user login form
struct LoginView: View {
    // MARK: - Published State

    /// Manager object for user authentication
    @ObservedObject var authManager: AuthManager

    /// User email
    @State private var email = ""

    /// User password
    @State private var password = ""

    /// Control to show different views while authentication is running asynchronously
    @State private var isAuthenticating = false

    /// Message store for errors to display to users for UI/UX
    @State private var errorMessage: String?

    // MARK: - Init

    init(authManager: AuthManager) {
        self.authManager = authManager

        if APIConfig.mode == "DEMO" {
            _email = State(initialValue: "tester@example.com")
            _password = State(initialValue: "password123")
        } else {
            _email = State(initialValue: "")
            _password = State(initialValue: "")
        }
    }

    // MARK: - Computed Properties

    /// Computed control to disable login during authentication or when running demo mode
    private var shouldDisableLogin: Bool {
        if isAuthenticating {
            return true
        }
        if APIConfig.mode != "DEMO" {
            return email.isEmpty || password.isEmpty
        }
        return false
    }

    /// Computed control to disable textboxes during authentication or when running demo mode
    private var shouldDisableInput: Bool {
        if isAuthenticating {
            return true
        }
        if APIConfig.mode == "DEMO" {
            return true
        }
        return false
    }

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

                    Text("Master output through targeted journaling.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: UIConstants.Spacing.content) {
                    if APIConfig.mode != "DEMO" {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .frame(width: 280, height: 45)
                        .disabled(isAuthenticating)

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
                    } else {
                        Text("DEMO VERSION")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: UIConstants.Spacing.section) {
                        TextField(
                            "Email",
                            text: APIConfig.mode != "DEMO" ? $email : .constant("tester@example.com"),
                        )
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        #endif
                            .frame(width: 280, height: 45)
                            .disabled(shouldDisableInput)

                        SecureField(
                            "Password",
                            text: APIConfig.mode != "DEMO" ? $password : .constant("password123"),
                        )
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .frame(width: 280, height: 45)
                        .disabled(shouldDisableInput)
                    }

                    Button {
                        handleEmailSignIn()
                    } label: {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isAuthenticating ? "Signing in..." : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(shouldDisableLogin)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, UIConstants.Padding.largeIndent)

                Spacer()

                VStack(spacing: UIConstants.Spacing.row) {
                    Text("Don't have an account?")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Sign Up") {
                        // TODO: Navigate to sign up
                    }
                    .font(.caption)
                    .disabled(shouldDisableInput)
                }
                .padding(.bottom, UIConstants.Padding.largeIndent)
            }
        }
        .background {
            LinearGradient(
                colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Helper Methods

    /// Authentication error handler and caller for OAuth
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8)
            else {
                errorMessage = "Failed to process Apple Sign-In credentials"
                return
            }

            let userID = credential.user

            authenticateWithApple(identityToken: identityToken, userID: userID)

        case let .failure(error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled
            {
                return // User canceled, don't show error
            }
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }

    /// Authentication wrapper for OAuth sign in
    private func authenticateWithApple(identityToken: String, userID: String) {
        isAuthenticating = true
        errorMessage = nil

        let request = AppleAuthRequest(identityToken: identityToken, userID: userID)

        Task {
            let result = await postAppleAuthRequest(request)

            await MainActor.run {
                handleAuthResult(result)
            }
        }
    }

    /// Authentication wrapper for OAuth sign in
    private func handleEmailSignIn() {
        guard !email.isEmpty, !password.isEmpty else { return }

        isAuthenticating = true
        errorMessage = nil

        let request = EmailAuthRequest(identity: email, password: password)

        Task {
            let result = await postEmailAuthRequest(request)

            await MainActor.run {
                handleAuthResult(result)
            }
        }
    }

    /// Authentication error handler for decoding database login response
    private func handleAuthResult(_ result: Result<AuthResponse, AuthError>) {
        isAuthenticating = false

        switch result {
        case let .success(response):
            authManager.login(with: response)

        case let .failure(error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview {
    LoginView(authManager: AuthManager())
}
