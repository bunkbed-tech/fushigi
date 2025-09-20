//
//  SearchView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/21.
//

import SwiftUI

// MARK: - Search View

/// Dedicated search interface for iOS that displays filtered content from the other main app views. MacOS does not
/// need this because it has searchbars embedded into each page natively in the toolbar.
struct SearchView: View {
    // MARK: - Published State

    @EnvironmentObject var grammarStore: GrammarStore
    @State private var lastActiveView: AppNavigatorView.MainView = .journal
    /// Search query text binding provided from parent view search toolbar
    @Binding var searchText: String
    @Binding var selectedView: AppNavigatorView.MainView
    @Binding var selectedJournalEntry: JournalEntryLocal?
    @Binding var selectedGrammarPoint: GrammarPointLocal?

    // MARK: - Main View

    var body: some View {
        Group {
            showViewWithSearch(for: lastActiveView)
        }
        .onAppear {
            if selectedView != .search {
                lastActiveView = selectedView
            }
        }
        .onChange(of: selectedView) { _, newValue in
            if newValue != .search {
                lastActiveView = newValue
            }
        }
    }

    // MARK: - Helper Methods

    /// Search on mobile is implemented as a "portal" into the view that the searchbar was tapped from.
    ///
    /// This keeps things simple so I do not need to implement an entire new View just for search, although that
    /// is a common SwiftUI pattern in modern apps. This was done due to a combination of sheer laziness and
    /// the fact that I think it looks better.
    @ViewBuilder
    private func showViewWithSearch(for tab: AppNavigatorView.MainView) -> some View {
        switch tab {
        case .journal:
            JournalView(
                searchText: $searchText,
                selectedJournalEntry: $selectedJournalEntry,
                showNewEntry: .constant(false), // TODO: make not visible?
            )

        case .reference:
            ReferenceView(
                searchText: $searchText,
                selectedGrammarPoint: $selectedGrammarPoint,
            )

        case .search:
            // Fallback should never happen
            Text("ERROR: This should not happen... log bug.")
        }
    }
}
