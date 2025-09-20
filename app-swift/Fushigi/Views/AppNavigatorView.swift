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
/// for MacOS. This was done because a Navigation Split View looks great on MacOS (and iPad) but terrible on
/// mobile iOS. Tabs is a much more user friendly UX pattern. This navigator is used to clean switch between the
/// two and define the toolbar that should persist across all views.
struct AppNavigatorView: View {
    // MARK: - Published State

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #if os(macOS)
        @Environment(\.openSettings) private var openSettings
    #endif
    @State private var selectedView: MainView = .journal
    @State private var selectedJournalEntry: JournalEntryLocal?
    @State private var selectedGrammarPoint: GrammarPointLocal?
    @State private var showNewEntry = false
    /// Search query text binding provided from parent view search toolbar
    @State private var searchText: String = ""
    /// Controls whether the users account pops up as a sheet  (iOS only)
    @State private var showProfile = false

    // MARK: - Computed Properties

    /// Flag to get iPadOS to utilize iOS features vs MacOS features based on window size
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Hacky trick to get away from iOS required an optional on List for selectedView
    private var selectedViewBinding: Binding<MainView?> {
        Binding(
            get: { selectedView },
            set: { selectedView = $0 ?? .journal },
        )
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
                Tab(MainView.journal.id, systemImage: MainView.journal.icon, value: .journal) {
                    NavigationStack {
                        JournalView(
                            searchText: $searchText,
                            selectedJournalEntry: $selectedJournalEntry,
                            showNewEntry: $showNewEntry,
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .searchableIf(!isCompact, text: $searchText)
                        .toolbar {
                            profileToolbarButton
                        }
                        .sheet(item: $selectedJournalEntry) { entry in
                            SubNavigatorView(title: "", onDismiss: {}) {
                                JournalEntryDetailView(journalEntry: entry)
                            }
                        }
                        .sheet(isPresented: $showNewEntry) {
                            SubNavigatorView(title: "", onDismiss: {}) {
                                PracticeView()
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
                }

                Tab(MainView.reference.id, systemImage: MainView.reference.icon, value: .reference) {
                    NavigationStack {
                        ReferenceView(
                            searchText: $searchText,
                            selectedGrammarPoint: $selectedGrammarPoint,
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .searchableIf(!isCompact, text: $searchText)
                        .toolbar {
                            profileToolbarButton
                        }
                        .sheet(item: $selectedGrammarPoint) { grammarPoint in
                            SubNavigatorView(
                                title: "Grammar Details",
                                onDismiss: { selectedGrammarPoint = nil },
                            ) {
                                GrammarInspector(selectedGrammarPoint: grammarPoint)
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
                }

                Tab(value: .search, role: .search) {
                    NavigationStack {
                        SearchView(
                            searchText: $searchText,
                            selectedView: $selectedView,
                            selectedJournalEntry: $selectedJournalEntry,
                            selectedGrammarPoint: $selectedGrammarPoint,
                        )
                        .navigationTitle(MainView.search.id + " Mode")
                        .navigationBarTitleDisplayMode(.inline)
                        .searchable(text: $searchText)
                        .toolbar {
                            profileToolbarButton
                        }
                        .sheet(item: $selectedJournalEntry) { entry in
                            SubNavigatorView(title: "", onDismiss: {}) {
                                JournalEntryDetailView(journalEntry: entry)
                            }
                        }
                        .sheet(item: $selectedGrammarPoint) { grammarPoint in
                            SubNavigatorView(
                                title: "Grammar Details",
                                onDismiss: { selectedGrammarPoint = nil },
                            ) {
                                GrammarInspector(selectedGrammarPoint: grammarPoint)
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
                }
            }
        #endif
    }

    /// Split view navigation optimized for regular layouts (iPad, macOS, iPhone landscape)
    @ViewBuilder
    private var navigationAsSplitView: some View {
        NavigationSplitView {
            List(selection: selectedViewBinding) {
                NavigationLink(value: MainView.journal) {
                    Label(MainView.journal.id, systemImage: MainView.journal.icon)
                }
                NavigationLink(value: MainView.reference) {
                    Label(MainView.reference.id, systemImage: MainView.reference.icon)
                }
            }
        } content: {
            Group {
                switch selectedView {
                case .journal:
                    JournalView(
                        searchText: $searchText,
                        selectedJournalEntry: $selectedJournalEntry,
                        showNewEntry: $showNewEntry,
                    )
                case .reference:
                    ReferenceView(
                        searchText: $searchText,
                        selectedGrammarPoint: $selectedGrammarPoint,
                    )
                case .search:
                    SearchView(
                        searchText: $searchText,
                        selectedView: $selectedView,
                        selectedJournalEntry: $selectedJournalEntry,
                        selectedGrammarPoint: $selectedGrammarPoint,
                    )
                }
            }
            .toolbar { profileToolbarButton }
            .background {
                LinearGradient(
                    colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
            }
            #if os(macOS)
            .toolbarBackground(Visibility.hidden, for: .windowToolbar)
            #endif
        } detail: {
            SubNavigatorView(title: "", onDismiss: {}) {
                switch selectedView {
                case .journal: journalDetailColumn
                case .reference: referenceDetailColumn
                case .search: searchDetailColumn
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search")
        .navigationTitle(selectedView.id)
    }

    @ViewBuilder
    private var journalDetailColumn: some View {
        Group {
            if showNewEntry {
                PracticeView()
            } else if let selectedJournalEntry {
                JournalEntryDetailView(journalEntry: selectedJournalEntry)
            } else {
                ContentUnavailableView {
                    Label("Select Journal Entry", systemImage: "book.closed")
                } description: {
                    Text("Choose an entry from the list to view details, or create a new entry")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    @ViewBuilder
    private var referenceDetailColumn: some View {
        if let selectedGrammarPoint {
            GrammarInspector(selectedGrammarPoint: selectedGrammarPoint)
        } else {
            ContentUnavailableView {
                Label("Select Grammar Point", systemImage: "text.book.closed")
            } description: {
                Text("Choose a grammar point from the list to view details")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                LinearGradient(
                    colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var searchDetailColumn: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text("This should not have happened. Log as a bug.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()
        }
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

    // MARK: - Helper Methods

    /// Defines the main navigatons of the app across all platforms, namely a place to practice via writing journal
    /// entries, a history of all journal entries, a reference page to view detailed grammar information, and a
    /// place to search the app overall.
    enum MainView: String, Identifiable, CaseIterable {
        case journal = "Journal"
        case reference = "Reference"
        case search = "Search"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .journal: "clock.arrow.2.circlepath"
            case .reference: "books.vertical.fill"
            case .search: "magnifyingglass"
            }
        }

        /// Flag to hide global search bar for some NavigationLinks in MacOS/iPadOS views.
        var supportsSearch: Bool {
            switch self {
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
