//
//  SettingsView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/07.
//

import SwiftUI

// MARK: - Settings Window

/// Unified preferences window popup for MacOS since that has better UX than a popup sheet, especially for
/// settings. Try to follow the normal pattern with tabs and a separate window.
struct SettingsWindow: View {
    // MARK: - App-wide Settings Storage

    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"
    @AppStorage("targetLanguage") private var targetLanguage = "jp"

    // MARK: - Main View

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

// MARK: - Settings Sheet

/// iOS-style profile popup sheet with native NavigationLinks that don't force moving to a new view
/// so users can easily go back to their original main page view they were on before clicking on the
/// account button.
struct SettingsSheet: View {
    // MARK: - App-wide Settings Storage

    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"
    @AppStorage("targetLanguage") private var targetLanguage = "jp"
    @Binding var showProfile: Bool

    // MARK: - Main View

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

/// Display a contact card showing the logged in user with login/edit functionality. This currently is
/// not set up to do anything and is hard coded.
///
/// TODO: Populate account info (name, email, avatar) from the current authenticated user
/// TODO: Implement edit and logout functionality
/// TODO: Add some basic user stats (item counts, days studied, data export, etc)
struct AccountPreferences: View {
    // MARK: - Main View

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

/// General app preferences such as language, display, etc. This wrapper was implemented in
/// order to easily use a List for iOS vs a Form for MacOS to improve UX. So far, it only lets users
/// choose different language settings although they don't do anything right now. Basically right now
/// this is just a placeholder.
///
/// TODO: Actual have these choices do something (such as show different Grammar/SRS/Journal items
/// TODO: Could try localizing the app to have the interface language actually change something
struct GeneralPreferences: View {
    // MARK: - Published State

    @Binding var interfaceLanguage: String
    @Binding var targetLanguage: String

    // MARK: - Main View

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

    // MARK: - Sub Views

    /// User selection for language settings should be a simple menu picker on both iOS and MacOS
    /// platforms. Currently available languages are hardcoded, but could be made to come from the
    /// PocketBase database instead.
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

/// Show card displaying current app version and 3rd party libraries used. This is done in order to stay
/// compliant with any 3rd party open source libraries as well as show users some simple app info such
/// as version, a nice logo, etc. Mostly just UX niceities.
struct CreditsPreferences: View {
    // MARK: - Main View

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
