//
//  ReferenceView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Reference View

/// Searchable grammar reference interface with detailed grammar point inspection. Filters are provided to
/// show not only default grammar points, but custom user added ones as well. SRS records can be both
/// generated and removed from this page. SRS records are what influences a users daily study recommendations.
struct ReferenceView: View {
    // MARK: - Published State

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var studyStore: StudyStore
    /// Controls whether the sheet for explicit grammar details pops up
    @State private var showDetails: Bool = false
    /// Controls currently displayed source of grammar (default, custom, in SRS, not in SRS, etc)
    @State private var selectedFilter: GrammarQuickFilter = .all
    /// Search query text binding provided from parent view search toolbar
    @Binding var searchText: String

    // MARK: Computed Properties

    /// Flag to get iPadOS to utilize iOS features vs MacOS features based on window size
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// When dealing with data dependent on both the SRS store and grammar store, use a composite
    /// that favors the SRS store's system state
    var effectiveSystemState: SystemState {
        if selectedFilter.requiresSRSData {
            studyStore.srsStore.systemState
        } else {
            studyStore.grammarStore.systemState
        }
    }

    /// Chooses displayed grammar points based on user selected search criteria and filter button. Note that
    /// default items are provided by the developer, while available items refer to grammar points currently
    /// stored on device or PocketBase that do not have a matching SRS record. This could be because it was
    /// a default the user didn't explicitly add or because they deleted a record when they no longer wanted to
    /// study it.
    var grammarPoints: [GrammarPointLocal] {
        let baseItems: [GrammarPointLocal] = switch selectedFilter {
        case .all:
            studyStore.grammarStore.grammarItems
        case .defaults:
            studyStore.grammarStore.systemGrammarItems
        case .custom:
            studyStore.grammarStore.userGrammarItems
        case .inSRS:
            studyStore.inSRSGrammarItems
        case .available:
            studyStore.availableGrammarItems
        }

        return studyStore.grammarStore.filterGrammarPoints(for: baseItems, containing: searchText)
    }

    /// Whether we should show the search empty state alerting user that no data currently exists for their current
    /// criteria. This empty
    /// state alert should show whenever the Reference View data source (grammarPoints) has data and there is an active
    /// search term
    /// (searchText). Ensuring the system state is normal also enforces that there isn't a loading sequence actively
    /// running.
    var shouldShowSearchEmptyState: Bool {
        grammarPoints.isEmpty &&
            !searchText.isEmpty &&
            effectiveSystemState == .normal
    }

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {
            if effectiveSystemState.shouldDisableUI {
                loadingProgressView
            }

            mainContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if case .degradedOperation = effectiveSystemState {
                Button(action: { Task { await studyStore.refresh() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Sync Issue")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                    .padding(.vertical, UIConstants.Padding.capsuleHeight)
                    .background(.orange.opacity(0.15))
                    .clipShape(.capsule)
                }
                .padding()
                .disabled(effectiveSystemState.shouldDisableUI)
            }
        }
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showDetails, onDismiss: {
            studyStore.grammarStore.selectedGrammarPoint = nil
        }) {
            GrammarInspector(
                showDetails: $showDetails,
                systemState: effectiveSystemState,
            )
        }
    }

    // MARK: - Sub Views

    /// Animated loading view to alert user a long async process is currently underway. It is a simple rotating spinner
    /// that goes away when system state is no longer in a state of loading. It does not deactivate any UI components
    /// although that is a desirable feature that should be handled in the parent view.
    @ViewBuilder
    private var loadingProgressView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Performing database sync actions...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
        }
    }

    /// Helper function to simplify code that displays error screens or a list/table of grammar content. Potential error
    /// screens include actual errors from the device during data load, actual errors from the PocketBase backend
    /// during data sync, or a state of there being no data at all despite healthy load procedures. During load, the
    /// UI should be completely disabled to help prevent user action from further breaking async processes.
    @ViewBuilder
    private var mainContentView: some View {
        if effectiveSystemState.shouldShowContentUnavailable {
            effectiveSystemState.contentUnavailableView(
                action: {
                    guard !effectiveSystemState.shouldDisableUI else { return }
                    await studyStore.refresh()
                },
            )
        } else if shouldShowSearchEmptyState {
            ContentUnavailableView.search(text: searchText)
        } else if grammarPoints.isEmpty {
            ContentUnavailableView {
                Label("\(selectedFilter.rawValue): Items Missing", systemImage: "tray")
            } description: {
                Text("Try adding new grammar points, changing the filter, or bulk generating SRS items from default.")
                    .foregroundColor(.secondary)
            }
        } else {
            GrammarTable(
                showDetails: $showDetails,
                grammarPoints: grammarPoints,
                isCompact: isCompact,
                onRefresh: {
                    guard !effectiveSystemState.shouldDisableUI else { return }
                    await studyStore.refresh()
                },
            )
            .disabled(effectiveSystemState.shouldDisableUI)
        }
    }

    /// Sorting and filtering action toolbar in the top trailing corner to let users choose a different grammar source
    /// for the purpose of adding and removing SRS records easily. During async processes it should be disabled
    /// to prevent user interaction.
    ///
    /// TODO: Implement bulk import and export from JSON
    /// TODO: Implement custom grammar creation interface
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                ForEach(GrammarQuickFilter.allCases, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        HStack {
                            Text(filter.rawValue)
                            if selectedFilter == filter {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .disabled(effectiveSystemState.shouldDisableUI)

            Menu("Options", systemImage: "ellipsis.circle") {
                Button("Bulk Import", systemImage: "square.and.arrow.down") {}.disabled(true)
                Button("Bulk Export", systemImage: "square.and.arrow.up") {}.disabled(true)
                Divider()
                Button("Create", systemImage: "rectangle.fill.badge.plus") {}.disabled(true)

                if selectedFilter == .available {
                    Button("Generate From Defaults", systemImage: "rectangle.stack.fill.badge.plus") {
                        Task {
                            await studyStore.srsStore.addBulkToSRS(studyStore.availableGrammarItems)
                        }
                    }
                    .disabled(studyStore.availableGrammarItems.isEmpty)
                }
            }
            .disabled(effectiveSystemState.shouldDisableUI)
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Degraded Operation Postgres") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("With Search Results") {
    ReferenceView(searchText: .constant("Hello"))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("No Search Results") {
    ReferenceView(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Loading State") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Empty Database") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Critical Error PocketBase") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .pocketbaseError)
}

#Preview("Critical Error SwiftData") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}

#Preview("Missing SRS") {
    ReferenceView(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(noSRS: true)
}
