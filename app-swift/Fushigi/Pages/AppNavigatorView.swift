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

    /// Profile sheet presentation state (iOS only)
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
        #if os(iOS)
        .sheet(isPresented: $showProfile) {
            IOSSettingsView(showProfile: $showProfile)
        }
        #endif
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
                            .navigationTitle(Page.search.id + " Mode Enabled")
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

    /// Unified account/settings button for both platforms
    @ToolbarContentBuilder
    private var profileToolbarButton: some ToolbarContent {
        #if os(iOS)
            let placement: ToolbarItemPlacement = .topBarLeading
        #else
            let placement: ToolbarItemPlacement = .navigation
        #endif

        ToolbarItem(placement: placement) {
            AccountButton(showProfile: $showProfile)
        }
    }

    /// Account button that opens settings (macOS) or sheet (iOS)
    struct AccountButton: View {
        @Binding var showProfile: Bool
        #if os(macOS)
            @Environment(\.openSettings) private var openSettings
        #endif

        var body: some View {
            Button("Account", systemImage: "person.circle") {
                #if os(macOS)
                    openSettings()
                #else
                    showProfile = true
                #endif
            }
        }
    }

    /// Returns the appropriate view for each app section
    @ViewBuilder
    private func decoratedView(for page: Page) -> some View {
        Group {
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
        .background {
            LinearGradient(
                colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()
        }
        #if os(macOS)
        // Ensure the gradient fills under the titlebar (why doesnt it by default?)
        .toolbarBackground(Visibility.hidden, for: .windowToolbar)
        #endif
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
