//
//  JournalView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Journal View

/// Displays user journal entries with search functionality and expandable detail view. Journal entries can be further
/// sorted by privacy settings in anticipation of future social features. The desire is to have each journal entry show
/// the entry itself, a list of grammar points used, and a feedback section. This feedback section should be able
/// to be sourced from on device AI using apple intelligence or potentially an Open AI API. The ability to rerun this
/// feedback from the dropdown is also a desirable feature.
struct JournalView: View {
    // MARK: - Published State

    @EnvironmentObject var journalStore: JournalStore
    @State private var errorMessage: String?
    /// Set of expanded journal entry IDs for detail view since many can be "open" at once
    @State private var expanded: Set<String> = []
    /// Control to set order in which journal entries are shown for the user
    @State private var journalSortKey: JournalSort = .newest
    /// Control to swap between all, private, and public journal entries in anticipation of potential social features
    @State private var selectedFilter: JournalQuickFilter = .all
    /// Search query text binding provided from parent view search toolbar
    @Binding var searchText: String

    // MARK: - Computed Properties

    /// Filtered journal entries based on current search criteria comfing from interactive dropdown button
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

    /// Determine the health of the most important store for this view (Journal), whether it's an error state,
    /// loading state, or healthy state
    private var systemState: SystemState {
        journalStore.systemState
    }

    /// Whether we should show the search empty state alerting user that no data currently exists for their current
    /// criteria. This empty
    /// state alert should show whenever the Journal View data source (journalEntries) has data and there is an active
    /// search term
    /// (searchText). Ensuring the system state is normal also enforces that there isn't a loading sequence actively
    /// running.
    var shouldShowSearchEmptyState: Bool {
        journalEntries.isEmpty &&
            !searchText.isEmpty &&
            systemState == .normal &&
            hasDataForCurrentFilter
    }

    /// Content available boolean check needs to be recomputed for each data source depending on the users currently
    /// selected
    /// sorting filter
    var hasDataForCurrentFilter: Bool {
        if selectedFilter == .all {
            !journalStore.journalEntries.isEmpty
        } else if selectedFilter == .isPrivate {
            !journalStore.privateJournalEntries.isEmpty
        } else {
            !journalStore.publicJournalEntries.isEmpty
        }
    }

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {
            switch systemState {
            case .loading, .emptyData, .criticalError:
                systemState.contentUnavailableView(action: {
                    if case .emptyData = systemState {
                        searchText = ""
                    }
                    await journalStore.refresh()
                })
            case .normal, .degradedOperation:
                mainContentView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // necessary for empty search
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
    }

    // MARK: - Sub Views

    /// Choose whether to show an empty view dpending on the current data and health state, or a list of all journal
    /// entries. This was
    /// separated from the main code in order to aid in XCode compilation.
    @ViewBuilder
    private var mainContentView: some View {
        if !hasDataForCurrentFilter {
            ContentUnavailableView {
                Label("No \(selectedFilter.rawValue)", systemImage: "tray")
            } description: {
                Text("Try writing a new journal entry on the Practice page.")
                    .foregroundColor(.secondary)
            }
        } else if shouldShowSearchEmptyState {
            ContentUnavailableView.search(text: searchText)
        } else {
            List {
                ForEach(journalEntries) { entry in
                    journalItemDisclosure(for: entry)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await journalStore.refresh()
            }
            .scrollContentBackground(.hidden)
        }
    }

    /// Implement a list of journal items as a disclosure group (click and drop down) rather than a clickable list with
    /// a pop up
    /// sheet or navigation. This was done mostly to experiment with disclure groups although I am a fan of the UX.
    /// Potentially
    /// might want to move on from this method to something more standard based on feedback.
    ///
    /// TODO: Display tagged grammar points and feedback rather than hardcode them.
    /// TODO: Include buttons for recomputing feedback.
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

    /// Toggles the expanded state for the currently clicked journal entry so it expands and show content. Toggling is
    /// implemented via a Set of indexes storing whether the current index is open or closed.
    private func toggleExpanded(for id: String) {
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }

    /// Swipe to delete is provided on an index by the Swift SDK so remove the current journal entry at that offset
    /// when the user swipes.
    ///
    /// TODO: Actually implement this feature
    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            let deletedEntry = journalEntries[index]
            print("LOG: Removing entry: \(deletedEntry)")
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Data Missing") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Degraded Operation Postgres") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("No Search Results") {
    JournalView(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Loading State") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Critical Postgres Error") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .pocketbaseError)
}

#Preview("Critical SwiftData Error") {
    JournalView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}
