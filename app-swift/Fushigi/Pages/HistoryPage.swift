//
//  HistoryPage.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - History Page

/// Displays user journal entries with search and expandable detail view
struct HistoryPage: View {
    /// Centralized journal entry repository with synchronization capabilities
    @EnvironmentObject var journalStore: JournalStore

    /// Error message to display if data fetch fails
    @State private var errorMessage: String?

    /// Set of expanded journal entry IDs for detail view
    @State private var expanded: Set<UUID> = []

    /// Search text binding from parent view
    @Binding var searchText: String

    /// Filtered journal entries based on current search criteria
    var journalEntries: [JournalEntryLocal] {
        journalStore.filterJournalEntries(containing: searchText)
    }

    /// Current primary state for UI rendering decisions
    var systemState: SystemState {
        journalStore.systemState
    }

    // MARK: - Main View

    var body: some View {
        Group {
            switch systemState {
            case .loading, .emptyData, .criticalError:
                systemState.contentUnavailableView {
                    if case .emptyData = systemState {
                        searchText = ""
                    }
                    await journalStore.refresh()
                }
            case .normal, .degradedOperation:
                List {
                    if case .degradedOperation = systemState {
                        systemState.errorBannerView {
                            await journalStore.refresh()
                        }
                    }
                    ForEach(journalEntries) { entry in
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.title)
                                        .font(.headline)
                                    Text(entry.createdAt.formatted())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: expanded.contains(entry.id) ?
                                    "chevron.down" : "chevron.right")
                                    .animation(.none, value: expanded.contains(entry.id))
                            }

                            if expanded.contains(entry.id) {
                                VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                                    Text(entry.content)

                                    VStack(alignment: .leading, spacing: UIConstants.Spacing.tightRow) {
                                        Text("Grammar Points:")
                                            .font(.subheadline)
                                            .foregroundStyle(.mint)
                                        Text("• (placeholder) ～てしまう")
                                        Text("• (placeholder) ～わけではない")
                                    }

                                    VStack(alignment: .leading, spacing: UIConstants.Spacing.tightRow) {
                                        Text("AI Feedback:")
                                            .font(.subheadline)
                                            .foregroundStyle(.purple)
                                        Text("(placeholder) Try to avoid passive constructions.")
                                    }
                                }
                                .padding(.leading)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture { // hilarious animation...
                            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.3)) {
                                toggleExpanded(for: entry.id)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button("Edit") {
                                print("LOG: Share entry: \(entry.title)")
                            }
                            .tint(.gray)

                            Button("Delete", role: .destructive) {
                                if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
                                    deleteEntry(at: IndexSet(integer: index))
                                }
                            }
                            .tint(.red)
                        }
                        .swipeActions(edge: .leading) {
                            Button("Pin") {
                                // Pin/favorite action
                                print("LOG: Pin entry: \(entry.title)")
                            }
                            .tint(.mint)

                            Button("Share") {
                                // Edit action
                                print("LOG: Edit entry: \(entry.title)")
                            }
                            .tint(.purple)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    // TODO: Janky, need to fix refreshable
                    await journalStore.refresh()
                }
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                Button("Newest First") { /* TODO: Implement sorting */ }
                Button("Oldest First") { /* TODO: Implement sorting */ }
                Button("By Title") { /* TODO: Implement sorting */ }
            }

            Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                Button("All Entries") { /* TODO: Implement filtering */ }
                Button("Private Only") { /* TODO: Implement filtering */ }
                Button("Public Only") { /* TODO: Implement filtering */ }
                Divider()
                Button("This Week") { /* TODO: Implement filtering */ }
                Button("This Month") { /* TODO: Implement filtering */ }
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

    /// Toggle expanded state for journal entry
    private func toggleExpanded(for id: UUID) {
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }

    /// Delete journal entries at specified offsets
    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            let deletedEntry = journalEntries[index]
            print("LOG: Pretending to delete: \(deletedEntry.title)")
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Data Missing") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .healthy)
}

#Preview("Degraded Operation Postgres") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .postgresError)
}

#Preview("Degraded Operation SwiftData") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .swiftDataError)
}

#Preview("No Search Results") {
    HistoryPage(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Loading State") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading, systemHealth: .healthy)
}

#Preview("Critical Postgres Error") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .postgresError)
}

#Preview("Critical SwiftData Error") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}
