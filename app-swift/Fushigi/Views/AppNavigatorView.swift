//
//  AppNavigatorView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftData
import SwiftUI

// MARK: - Navigation View Wrapper

/// Simplify the overall app navigation across platforms. Use a container with adaptive layout for tabs and split view
/// for MacOS. This was
/// done because a Navigation Split View looks great on MacOS (and iPad) but terrible on mobile iOS. Tabs is a much more
/// user friendly
/// UX pattern. This navigator is used to clean switch between the two and define the toolbar that should persist across
/// all views.
struct AppNavigatorView: View {
    // MARK: - Published State

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #if os(macOS)
        @Environment(\.openSettings) private var openSettings
    #endif
    @State private var selectedView: MainView? = .practice
    /// Search query text binding provided from parent view search toolbar
    @State private var searchText: String = ""
    /// Controls whether the users account pops up as a sheet  (iOS only)
    @State private var showProfile = false

    // MARK: - Computed Properties

    /// Flag to get iPadOS to utilize iOS features vs MacOS features based on window size
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

    /// Unified account/settings button for both platforms used in order to either open as a sheet or a
    /// separate window
    @ToolbarContentBuilder
    private var profileToolbarButton: some ToolbarContent {
        #if os(iOS)
            let placement: ToolbarItemPlacement = .topBarLeading
        #else
            let placement: ToolbarItemPlacement = .navigation
        #endif

        ToolbarItem(placement: placement) {
            Button("Account", systemImage: "person.circle") {
                #if os(macOS)
                    openSettings()
                #else
                    showProfile = true
                #endif
            }
        }
    }

    /// Call the exact view for the selected tab/navigation and add a nice mostly transparent linear gradient
    /// as a background to make the app feel more friendly and modern for users. This also makes things
    /// look nicer with Liquid Glass.
    ///
    /// Note that there is weird MacOS behavior requiring forcing the toolbar to be see through in order to
    /// have the linear gradient show up behind the top nav toolbar (something that doesn't happen on iOS
    /// already by default).
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

    /// Defines the main navigatons of the app across all platforms, namely a place to practice via writing journal
    /// entries,
    /// a history of all journal entries, a reference page to view detailed grammar information, and a place to search
    /// the
    /// app overall.
    enum MainView: String, Identifiable, CaseIterable {
        case practice = "Practice"
        case journal = "Journal"
        case reference = "Reference"
        case search = "Search"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .practice: "pencil.and.scribble"
            case .journal: "clock.arrow.2.circlepath"
            case .reference: "books.vertical.fill"
            case .search: "magnifyingglass"
            }
        }

        /// Flag to hide global search bar for some NavigationLinks in MacOS/iPadOS views.
        /// TODO: Fix this, the search bar still shows up on the .practice page.
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
