//
//  AppNavigatorView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftData
import SwiftUI

// MARK: - Navigation View Wrapper

/// Main navigation container with adaptive layout for tabs and split view
struct AppNavigatorView: View {
    /// Responsive layout detection for adaptive navigation structure
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Currently active application section, coordinating tab/sidebar selection
    @State private var selectedPage: Page? = .practice

    /// Shared search query state for views that support content filtering
    @State private var searchText: String = ""

    /// Profile sheet presentation state
    @State private var showProfile = false

    /// Determines whether to use compact navigation patterns (tabs vs split view)
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    // MARK: - Main View

    var body: some View {
        Group {
            if isCompact {
                navigationAsTabs
                    .tabBarMinimizeOnScrollIfAvailable()
            } else {
                navigationAsSplitView
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(showProfile: $showProfile)
        }
    }

    // MARK: - Helper Methods

    /// Tab-based navigation optimized for compact layouts (iPhone portrait, small windows)
    @ViewBuilder
    private var navigationAsTabs: some View {
        #if os(iOS)
            TabView(selection: $selectedPage) {
                Tab(Page.practice.id, systemImage: Page.practice.icon, value: .practice) {
                    NavigationStack {
                        decoratedView(for: .practice)
                            .navigationTitle(Page.practice.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }

                Tab(Page.history.id, systemImage: Page.history.icon, value: .history) {
                    NavigationStack {
                        decoratedView(for: .history)
                            .navigationTitle(Page.history.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchableIf(!isCompact, text: $searchText)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }

                Tab(Page.reference.id, systemImage: Page.reference.icon, value: .reference) {
                    NavigationStack {
                        decoratedView(for: .reference)
                            .navigationTitle(Page.reference.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchableIf(!isCompact, text: $searchText)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }

                Tab(value: .search, role: .search) {
                    NavigationStack {
                        decoratedView(for: .search)
                            .navigationTitle(Page.search.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchable(text: $searchText)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }
            }
        #endif
    }

    /// Split view navigation optimized for regular layouts (iPad, macOS, iPhone landscape)
    @ViewBuilder
    private var navigationAsSplitView: some View {
        NavigationSplitView {
            List(selection: $selectedPage) {
                NavigationLink(value: Page.practice) {
                    Label(Page.practice.id, systemImage: Page.practice.icon)
                }
                NavigationLink(value: Page.history) {
                    Label(Page.history.id, systemImage: Page.history.icon)
                }
                NavigationLink(value: Page.reference) {
                    Label(Page.reference.id, systemImage: Page.reference.icon)
                }
            }
        }
        detail: {
            if let selectedPage {
                decoratedView(for: selectedPage)
                    .toolbar {
                        profileToolbarButton
                    }
            } else {
                ContentUnavailableView {
                    Label("Current tab state broken", systemImage: "error")
                } description: {
                    Text("Illegal tab state bug. Please report this issue.")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search")
        .navigationTitle(selectedPage?.id ?? "Fushigi")
    }

    /// Reusable profile toolbar button
    @ToolbarContentBuilder
    private var profileToolbarButton: some ToolbarContent {
        #if os(iOS)
        let placement: ToolbarItemPlacement = .topBarLeading
        #else
        let placement: ToolbarItemPlacement = .navigation
        #endif

        ToolbarItem(placement: placement) {
            Button("Profile", systemImage: "person.circle") {
                showProfile = true
            }
        }
    }

    /// Returns the appropriate view for each app section
    @ViewBuilder
    private func decoratedView(for page: Page) -> some View {
        switch page {
        case .practice:
            PracticePage()
        case .history:
            HistoryPage(searchText: $searchText)
        case .reference:
            ReferencePage(searchText: $searchText)
        case .search:
            SearchPage(searchText: $searchText, selectedPage: $selectedPage)
        }
    }

    /// Application sections with navigation metadata
    enum Page: String, Identifiable, CaseIterable {
        case practice = "Practice"
        case history = "History"
        case reference = "Reference"
        case search = "Search"

        var id: String { rawValue }

        /// System icon name for navigation
        var icon: String {
            switch self {
            case .practice: "pencil.and.scribble"
            case .history: "clock.arrow.2.circlepath"
            case .reference: "books.vertical.fill"
            case .search: "magnifyingglass"
            }
        }

        /// Flag to hide global search bar for some NavigationLinks in MacOS/iPadOS views
        var supportsSearch: Bool {
            switch self {
            case .practice: false
            case .history: true
            case .reference: true
            case .search: false
            }
        }
    }
}

// MARK: - Profile View

/// User profile and settings view presented as a sheet
struct ProfileView: View {
    @Binding var showProfile: Bool

    var body: some View {
        NavigationStack {
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

                Section("App Information") {
                    NavigationLink("Preferences", destination: PreferencesView())
                    NavigationLink("Credits & Licenses", destination: CreditsView())
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        print("TODO: Implement sign out")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        showProfile = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: .constant(.large))
    }
}

// MARK: - Credits View

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.content) {
                Text("Third Party Libraries")
                    .font(.title2)
                    .bold()

                VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                    Text("WrappingHStack")
                        .font(.headline)

                    Text("""
                    MIT License

                    Copyright (c) 2022 Konstantin Semianov

                    Permission is hereby granted, free of charge, to any person obtaining a copy
                    of this software and associated documentation files (the "Software"), to deal
                    in the Software without restriction, including without limitation the rights
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                    copies of the Software, and to permit persons to whom the Software is
                    furnished to do so, subject to the following conditions:

                    The above copyright notice and this permission notice shall be included in all
                    copies or substantial portions of the Software.

                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                    SOFTWARE.
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Credits")
    }
}

// MARK: - Placeholder Views

struct PreferencesView: View {
    var body: some View {
        Text("TODO: Preferences/Language Settings")
            .navigationTitle("Preferences")
    }
}

// MARK: - Previews

#Preview("Normal State") {
    AppNavigatorView()
        .withPreviewStores()
}

#Preview("Empty Data State") {
    AppNavigatorView()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Sync Error State") {
    AppNavigatorView()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("Load State") {
    AppNavigatorView()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Remote Connection State") {
    AppNavigatorView()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Missing SRS") {
    AppNavigatorView()
        .withPreviewStores(systemState: .emptySRS)
}

