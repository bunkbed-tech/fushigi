//
//  HistoryPage.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - History Page

enum JournalSort: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case title = "By Title"
}

enum JournalQuickFilter: String, CaseIterable {
    case all = "All Entries"
    case isPrivate = "Private Only"
    case isPublic = "Public Only"
}

/// Displays user journal entries with search and expandable detail view
struct HistoryPage: View {
    /// Centralized journal entry repository with synchronization capabilities
    @EnvironmentObject var journalStore: JournalStore

    /// Error message to display if data fetch fails
    @State private var errorMessage: String?

    /// Set of expanded journal entry IDs for detail view
    @State private var expanded: Set<String> = []

    /// Control to set order in which journal entries are shown for the user
    @State private var journalSortKey: JournalSort = .newest

    /// Controls currently displayed source of journal entry
    @State private var selectedFilter: JournalQuickFilter = .all

    /// Search text binding from parent view
    @Binding var searchText: String

    /// Filtered journal entries based on current search criteria
    var journalEntries: [JournalEntryLocal] {
        let baseItems: [JournalEntryLocal] = switch selectedFilter {
        case .all:
            journalStore.journalEntries
        case .isPrivate:
            journalStore.privateJournalEntries
        case .isPublic:
            journalStore.publicJournalEntries
        }

        return journalStore.getJournalEntries(for: baseItems, sortedBy: journalSortKey, containing: searchText)
    }

    /// Current primary state for UI rendering decisions
    private var systemState: SystemState {
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
            case .normal, .degradedOperation, .emptySRS:
                List {
                    ForEach(journalEntries) { entry in
                        journalItemDisclosure(for: entry)
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
        .overlay(alignment: .topTrailing) {
            if case .degradedOperation = systemState {
                Button(action: { Task { await journalStore.refresh() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Sync Issue")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .clipShape(.capsule)
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
        }
        .toolbar {
            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                ForEach(JournalSort.allCases, id: \.self) { filter in
                    if journalSortKey == filter {
                        Button(filter.rawValue, systemImage: "checkmark") {
                            journalSortKey = filter
                        }
                    } else {
                        Button(filter.rawValue) {
                            journalSortKey = filter
                        }
                    }
                }
            }

            Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                ForEach(JournalQuickFilter.allCases, id: \.self) { filter in
                    if selectedFilter == filter {
                        Button(filter.rawValue, systemImage: "checkmark") {
                            selectedFilter = filter
                        }
                    } else {
                        Button(filter.rawValue) {
                            selectedFilter = filter
                        }
                    }
                }
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
    func journalItemDisclosure(for entry: JournalEntryLocal) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.title)
                        .font(.headline)
                    Text(entry.created.formatted())
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
            Button("Delete") {
                if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
                    deleteEntry(at: IndexSet(integer: index))
                }
            }
            .tint(.red)
        }
    }

    // MARK: - Helper Methods

    /// Toggle expanded state for journal entry
    private func toggleExpanded(for id: String) {
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
            print("TODO: Pretending to delete: \(deletedEntry.title)")
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Data Missing") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Degraded Operation Postgres") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("No Search Results") {
    HistoryPage(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Loading State") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Critical Postgres Error") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .pocketbaseError)
}

#Preview("Critical SwiftData Error") {
    HistoryPage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}
