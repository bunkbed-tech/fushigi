//
//  SearchView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/21.
//

import SwiftUI

// MARK: - Search View

/// Dedicated search interface for iOS that displays filtered content from other app sections
struct SearchView: View {
    // MARK: - Published State

    /// Grammar store for data access
    @EnvironmentObject var grammarStore: GrammarStore

    /// Last active tab to determine which content to search
    @State private var lastActiveTab: AppNavigatorView.MainView = .practice

    /// Search query text binding from parent view
    @Binding var searchText: String

    /// Currently selected main view binding for tracking context
    @Binding var selectedView: AppNavigatorView.MainView?

    // MARK: - Main View

    var body: some View {
        Group {
            // Just show the actual page with search applied!
            showViewWithSearch(for: lastActiveTab)
        }
        .onAppear {
            if let current = selectedView, current != .search {
                lastActiveTab = current
            }
        }
        .onChange(of: selectedView) { _, newValue in
            if let newValue, newValue != .search {
                lastActiveTab = newValue
            }
        }
    }

    // MARK: - Helper Methods

    /// Returns the appropriate page view with search applied
    @ViewBuilder
    private func showViewWithSearch(for tab: AppNavigatorView.MainView) -> some View {
        switch tab {
        case .practice:
            ReferenceView(searchText: $searchText)

        case .journal:
            JournalView(searchText: $searchText)

        case .reference:
            ReferenceView(searchText: $searchText)

        case .search:
            // Fallback should never happen
            Text("ERROR: This should not happen... log bug.")
        }
    }
}
