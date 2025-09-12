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
///
/// TODO: Fix the data analytics tab which is broken due to there being no data stores in the popup window
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

//            UserDataAnalytics()
//                .tabItem {
//                    Image(systemName: "chart.bar")
//                    Text("Analytics")
//                }
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
                            Spacer()
                            Button("Edit") {
                                print("TODO: Implement user edit")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, UIConstants.Padding.capsuleWidth)
                    }
                    .listRowBackground(Color.clear)

                    Section("Settings") {
                        NavigationLink("General", destination: GeneralPreferences(
                            interfaceLanguage: $interfaceLanguage,
                            targetLanguage: $targetLanguage,
                        )
                        .navigationTitle("General")
                        .navigationBarTitleDisplayMode(.inline))

                        NavigationLink("Credits & Licenses", destination: CreditsPreferences()
                            .navigationTitle("Credits & Licenses")
                            .navigationBarTitleDisplayMode(.inline))

                        NavigationLink("Analytics", destination: UserDataAnalytics()
                            .navigationTitle("Analytics")
                            .navigationBarTitleDisplayMode(.inline))
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        Button("Sign Out", role: .destructive) {
                            print("TODO: Implement sign out")
                        }
                    }
                    .listRowBackground(Color.clear)
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
                Button("Sign Out", role: .destructive) {
                    print("TODO: Sign out")
                }
                .buttonStyle(.borderedProminent)

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
            .containerBackground(.clear, for: .navigation)
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
        .listRowBackground(Color.clear)
    }
}

// MARK: - Credits Preferences Tab

/// Show card displaying current app version and 3rd party libraries used. This is done in order to stay
/// compliant with any 3rd party open source libraries as well as show users some simple app info such
/// as version, a nice logo, etc. Mostly just UX niceities.
struct CreditsPreferences: View {
    private var mitLicenseText: String {
        // swiftlint:disable:next line_length
        "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
    }

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
                            Text(mitLicenseText)
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
        #if os(iOS)
        .containerBackground(.clear, for: .navigation)
        #endif
    }
}

// MARK: - User Stats

/// Settings view that shows users a super brief rollup of the app stats. This acts as an actual
/// analytics view that may one day become more useful, but it is especially useful during
/// debugging the app for me.
struct UserDataAnalytics: View {
    @EnvironmentObject var studyStore: StudyStore
    @State private var analytics: StudyAnalytics?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading analytics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let analytics {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
                    // Overview Card
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        Text("Study Overview")
                            .font(.title2)
                            .fontWeight(.semibold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: UIConstants.Spacing.content) {
                            StatCard(
                                title: "Grammar Points",
                                value: "\(analytics.totalGrammarPoints)",
                                subtitle: "\(analytics.systemGrammarPoints) system, \(analytics.userGrammarPoints) yours",
                            )

                            StatCard(
                                title: "SRS Records",
                                value: "\(analytics.totalSRSRecords)",
                                subtitle: "\(analytics.recordsDue) due today",
                            )

                            StatCard(
                                title: "Sentences",
                                value: "\(analytics.totalSentences)",
                                subtitle: "Tagged examples",
                            )

                            if let mostUsed = analytics.mostUsedGrammar {
                                StatCard(
                                    title: "Most Practiced",
                                    value: mostUsed,
                                    subtitle: "Top grammar point",
                                )
                            }
                        }
                    }

                    Divider()

                    // Raw Counts (for debugging)
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        Text("Debug Info")
                            .font(.title3)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: UIConstants.Spacing.tightRow) {
                            Text("SRS Items: \(studyStore.inSRSGrammarItems.count)")
                            Text("Available: \(studyStore.availableGrammarItems.count)")
                            Text("Current Sentences: \(studyStore.sentenceBank.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                Text("Analytics not available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(iOS)
        .containerBackground(.clear, for: .navigation)
        #endif
        .task {
            analytics = await studyStore.getStudyAnalytics()
            isLoading = false
        }
    }
}

// MARK: - Stat Card Component

/// Show stats as small cards similar to how other apps do it that I use for studying languages.
/// Generalize the view and let all displays use it to create quick view grid in the settings menu.
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.tightRow) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(UIConstants.Padding.largeIndent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary)
        .clipShape(.rect(cornerRadius: UIConstants.Padding.capsuleWidth))
    }
}

#Preview("Normal State") {
    AppNavigatorView()
        .withPreviewStores()
}
