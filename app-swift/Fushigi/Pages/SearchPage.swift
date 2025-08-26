//
//  SearchPage.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/21.
//

import SwiftUI

// MARK: - Search Page

/// Dedicated search interface that displays filtered content from other app sections
struct SearchPage: View {
    /// Search query text binding from parent view
    @Binding var searchText: String

    /// Currently selected page binding for tracking context
    @Binding var selectedPage: ContentView.Page?

    /// Grammar store for data access
    @EnvironmentObject var grammarStore: GrammarStore

    /// Last active tab to determine which content to search
    @State private var lastActiveTab: ContentView.Page = .practice

    // MARK: - Main View

    var body: some View {
        Group {
            if searchText.isEmpty {
                ContentUnavailableView {
                    Label("Search \(lastActiveTab.rawValue)", systemImage: "magnifyingglass")
                } description: {
                    Text("Enter a term to search within \(lastActiveTab.rawValue.lowercased()) content.")
                }
            } else {
                // Just show the actual page with search applied!
                showPageWithSearch(for: lastActiveTab)
            }
        }
        .onAppear {
            if let current = selectedPage, current != .search {
                lastActiveTab = current
            }
        }
        .onChange(of: selectedPage) { _, newValue in
            if let newValue, newValue != .search {
                lastActiveTab = newValue
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

    // MARK: - Helper Methods

    /// Returns the appropriate page view with search applied
    @ViewBuilder
    private func showPageWithSearch(for tab: ContentView.Page) -> some View {
        switch tab {
        case .practice:
            ReferencePage(searchText: $searchText)

        case .history:
            HistoryPage(searchText: $searchText)

        case .reference:
            ReferencePage(searchText: $searchText)

        case .search:
            // Fallback
            Text("This should not happen...")
        }
    }
}
