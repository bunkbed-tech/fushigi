//
//  LoginPage.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/24.
//

import SwiftUI

// MARK: - Login Page

/// Simple barebones login page stub, eventually gate data load behind this and authorization
struct LoginPage: View {
    /// Placeholder for logging in via email, eventually want auth
    @State private var email = "test@example.com"

    /// Placeholder for logging in with password, eventually want auth
    @State private var password = "password123"

    /// Flag to show loading animation
    @State private var isLoading = false

    /// Flag to gate app access until login is performed
    @Binding var isLoggedIn: Bool

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
//                        Text("Fushigi")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)

                        Text("Master output through targeted journaling.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Login form
                VStack(spacing: UIConstants.Spacing.content) {
                    VStack(spacing: UIConstants.Spacing.section) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
//                            .autocapitalization(.none)
//                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                    }

                    Button {
                        login()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Signing in..." : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
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

    private func login() {
        isLoading = true
        print("TODO: Faking login...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isLoggedIn = true
        }
    }
}

#Preview("Normal State") {
    LoginPage(isLoggedIn: .constant(false))
}
