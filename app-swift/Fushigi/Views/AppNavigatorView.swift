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
    // MARK: - Published State

    /// Responsive layout detection for adaptive navigation structure
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Currently active application section, coordinating tab/sidebar selection
    @State private var selectedView: MainView? = .practice

    /// Shared search query state for views that support content filtering
    @State private var searchText: String = ""

    /// Profile sheet presentation state (iOS only)
    @State private var showProfile = false

    // MARK: - Computed Properties

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
            SettingsSheet(showProfile: $showProfile)
        }
        #endif
    }

    // MARK: - Sub Views

    /// Tab-based navigation optimized for compact layouts (iPhone portrait, small windows)
    @ViewBuilder
    private var navigationAsTabs: some View {
        #if os(iOS)
            TabView(selection: $selectedView) {
                Tab(MainView.practice.id, systemImage: MainView.practice.icon, value: .practice) {
                    NavigationStack {
                        decoratedView(for: .practice)
                            .navigationTitle(MainView.practice.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }

                Tab(MainView.journal.id, systemImage: MainView.journal.icon, value: .journal) {
                    NavigationStack {
                        decoratedView(for: .journal)
                            .navigationTitle(MainView.journal.id)
                            .navigationBarTitleDisplayMode(.inline)
                            .searchableIf(!isCompact, text: $searchText)
                            .toolbar {
                                profileToolbarButton
                            }
                    }
                }

                Tab(MainView.reference.id, systemImage: MainView.reference.icon, value: .reference) {
                    NavigationStack {
                        decoratedView(for: .reference)
                            .navigationTitle(MainView.reference.id)
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
                            .navigationTitle(MainView.search.id + " Mode Enabled")
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
            List(selection: $selectedView) {
                NavigationLink(value: MainView.practice) {
                    Label(MainView.practice.id, systemImage: MainView.practice.icon)
                }
                NavigationLink(value: MainView.journal) {
                    Label(MainView.journal.id, systemImage: MainView.journal.icon)
                }
                NavigationLink(value: MainView.reference) {
                    Label(MainView.reference.id, systemImage: MainView.reference.icon)
                }
            }
        }
        detail: {
            if let selectedView {
                decoratedView(for: selectedView)
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
        .navigationTitle(selectedView?.id ?? "Fushigi")
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

    /// Returns the appropriate view for each app section
    @ViewBuilder
    private func decoratedView(for view: MainView) -> some View {
        Group {
            switch view {
            case .practice:
                PracticeView()
            case .journal:
                JournalView(searchText: $searchText)
            case .reference:
                ReferenceView(searchText: $searchText)
            case .search:
                SearchView(searchText: $searchText, selectedView: $selectedView)
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

    // MARK: - Helper Methods

    /// Application sections with navigation metadata
    enum MainView: String, Identifiable, CaseIterable {
        case practice = "Practice"
        case journal = "Journal"
        case reference = "Reference"
        case search = "Search"

        var id: String { rawValue }

        /// System icon name for navigation
        var icon: String {
            switch self {
            case .practice: "pencil.and.scribble"
            case .journal: "clock.arrow.2.circlepath"
            case .reference: "books.vertical.fill"
            case .search: "magnifyingglass"
            }
        }

        /// Flag to hide global search bar for some NavigationLinks in MacOS/iPadOS views
        var supportsSearch: Bool {
            switch self {
            case .practice: false
            case .journal: true
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
