//
//  ContentView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftData
import SwiftUI

// MARK: - Content View Wrapper

/// Main navigation container with adaptive layout for tabs and split view
struct ContentView: View {
    /// Responsive layout detection for adaptive navigation structure
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Flag to gate app access until login is performed
    @State private var isLoggedIn: Bool = false

    /// Currently active application section, coordinating tab/sidebar selection
    @State private var selectedPage: Page? = .practice

    /// Shared search query state for views that support content filtering
    @State private var searchText: String = "" // helps with tab bar search icon placement

    /// Determines whether to use compact navigation patterns (tabs vs split view)
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Toggle for which pages have valid search mechanics
    private var shouldShowSearch: Bool {
        selectedPage?.supportsSearch ?? false
    }

    // MARK: - Main View

    var body: some View {
        if isLoggedIn {
            if isCompact {
                navigationAsTabs
                    .tabBarMinimizeOnScrollIfAvailable()
            } else {
                navigationAsSplitView
            }
        } else {
            LoginPage(isLoggedIn: $isLoggedIn)
        }
    }

    // MARK: - Helper Methods

    /// Tab-based navigation optimized for compact layouts (iPhone portrait, small windows)
    @ViewBuilder
    private var navigationAsTabs: some View {
        // The following check is already basically guaranteed to be true but sometimes xcode complains without the if-s
        #if os(iOS)
            TabView(selection: $selectedPage) {
                Tab(Page.practice.id, systemImage: Page.practice.icon, value: .practice) {
                    NavigationStack {
                        decoratedView(for: .practice)
                            .navigationTitle(Page.practice.id)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }

                Tab(Page.history.id, systemImage: Page.history.icon, value: .history) {
                    NavigationStack {
                        decoratedView(for: .history)
                            .navigationTitle(Page.history.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchableIf(!isCompact, text: $searchText) // MacOS style search for iPadOS
                    }
                }

                Tab(Page.reference.id, systemImage: Page.reference.icon, value: .reference) {
                    NavigationStack {
                        decoratedView(for: .reference)
                            .navigationTitle(Page.reference.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchableIf(!isCompact, text: $searchText) // MacOS style search for iPadOS
                    }
                }

                // iOS 18+ dedicated search tab
                Tab(value: .search, role: .search) {
                    NavigationStack {
                        decoratedView(for: .search)
                            .navigationTitle(Page.search.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchable(text: $searchText)
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
            } else {
                // Fallback state for navigation edge cases
                ContentUnavailableView {
                    Label("Current tab state broken", systemImage: "error")
                } description: {
                    Text("Illegal tab state bug. Please report this issue.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .searchable(text: $searchText, prompt: "Search")
        .navigationTitle(selectedPage?.id ?? "Fushigi")
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

// MARK: - Previews

#Preview("Normal State") {
    ContentView()
        .withPreviewStores()
}

#Preview("Empty Data State") {
    ContentView()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Sync Error State") {
    ContentView()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("Load State") {
    ContentView()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("PostgreSQL Connection State") {
    ContentView()
        .withPreviewStores(systemHealth: .postgresError)
}
