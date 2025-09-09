//
//  SettingsView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/07.
//

import SwiftUI

// MARK: - Application Preferences

/// Unified preferences view for MacOS
struct SettingsView: View {
    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"
    @AppStorage("targetLanguage") private var targetLanguage = "jp"

    var body: some View {
        TabView {
            AccountPreferences()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Account")
                }

            GeneralPreferences(
                interfaceLanguage: $interfaceLanguage,
                targetLanguage: $targetLanguage,
            )
            .tabItem {
                Image(systemName: "gear")
                Text("General")
            }

            CreditsPreferences()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("Credits")
                }
        }
        .frame(width: UIConstants.Sizing.forcedFrameWidth, height: UIConstants.Sizing.forcedFrameHeight)
    }
}

/// iOS-style profile view with native NavigationLinks
struct IOSSettingsView: View {
    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"
    @AppStorage("targetLanguage") private var targetLanguage = "jp"
    @Binding var showProfile: Bool

    var body: some View {
        #if os(iOS)
            PlatformSheet(title: "Account", onDismiss: { showProfile = false }) {
                List {
                    Section("Account") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("John Tester")
                                    .font(.headline)
                                Text("tester@example.com")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, UIConstants.Padding.capsuleWidth)

                        Button("Edit Profile") {
                            print("TODO: Implement user edit")
                        }
                    }

                    Section("Settings") {
                        NavigationLink("General", destination: GeneralPreferences(
                            interfaceLanguage: $interfaceLanguage,
                            targetLanguage: $targetLanguage,
                        )
                        .navigationTitle("General")
                        .background(Color(.systemGroupedBackground)))
                        NavigationLink("Credits & Licenses", destination: CreditsPreferences()
                            .navigationTitle("Credits & Licenses")
                            .background(Color(.systemGroupedBackground)))
                    }

                    Section {
                        Button("Sign Out", role: .destructive) {
                            print("TODO: Implement sign out")
                        }
                    }
                }
            }
        #endif
    }
}

// MARK: - Account Preferences Tab

struct AccountPreferences: View {
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.content) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("John Tester")
                        .font(.headline)
                    Text("tester@example.com")
                        .font(.caption)
                }
                Spacer()
                Button("Sign Out") {
                    print("TODO: Sign out")
                }
                .foregroundColor(.red)

                Button("Edit...") {
                    print("TODO: Edit account")
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - General Preferences Tab

struct GeneralPreferences: View {
    @Binding var interfaceLanguage: String
    @Binding var targetLanguage: String

    var body: some View {
        #if os(iOS)
            List {
                languagePickers
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        #else
            Form {
                languagePickers
            }
            .formStyle(.grouped)
            .padding()
        #endif
    }

    @ViewBuilder
    private var languagePickers: some View {
        Section("Language") {
            Picker("Interface", selection: $interfaceLanguage) {
                Text("English").tag("en")
                Text("Japanese").tag("jp")
            }
            .pickerStyle(.menu)

            Picker("Target", selection: $targetLanguage) {
                Text("Japanese").tag("jp")
                Text("German").tag("de")
                Text("Portuguese").tag("pg")
            }
            .pickerStyle(.menu)
        }
    }
}

// MARK: - Credits Preferences Tab

struct CreditsPreferences: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.content) {
                // App info section
                VStack(spacing: UIConstants.Spacing.row) {
                    Image("Splash-AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIConstants.Sizing.bigIcons, height: UIConstants.Sizing.bigIcons)

                    Text("Fushigi")
                        .font(.title)
                        .fontWeight(.medium)

                    Text("Version 1.0.0 (soon)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Master output through targeted journaling.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)

                Divider()

                // Third party libraries
                VStack(alignment: .leading, spacing: UIConstants.Spacing.content) {
                    Text("Third Party Libraries")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                            Text("WrappingHStack")
                                .font(.headline)

                            Text("MIT License")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Copyright (c) 2022 Konstantin Semianov")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ScrollView {
                            Text("""
                                Permission is hereby granted, free of charge, to any person obtaining
                                a copy of this software and associated documentation files (the "Software"),
                                to deal in the Software without restriction, including without limitation
                                the rights to use, copy, modify, merge, publish, distribute, sublicense,
                                and/or sell copies of the Software, and to permit persons to whom the
                                Software is furnished to do so, subject to the following conditions:

                                The above copyright notice and this permission notice shall be included
                                in all copies or substantial portions of the Software.

                                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
                                OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                                FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                                AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                                LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                                OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                                SOFTWARE.
                            """)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        }
                        .frame(height: UIConstants.Sizing.contentMinHeight)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(.rect(cornerRadius: UIConstants.Padding.capsuleWidth))
                    }
                }
            }
            .padding()
        }
    }
}
