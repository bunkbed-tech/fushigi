//
//  ReferenceView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Reference View

/// Searchable grammar reference interface with detailed grammar point inspection
struct ReferenceView: View {
    // MARK: - Published State

    /// Responsive layout detection for adaptive table presentation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Controls detailed grammar point inspection interface visibility
    @State private var showDetails: Bool = false

    /// Controls currently displayed source of grammar
    @State private var selectedFilter: GrammarQuickFilter = .all

    /// Search query text coordinated with parent navigation structure
    @Binding var searchText: String

    // MARK: Computed Properties

    /// Determines layout strategy based on available horizontal space
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Computed system state based on current filter
    var effectiveSystemState: SystemState {
        if selectedFilter.requiresSRSData {
            studyStore.srsStore.systemState
        } else {
            studyStore.grammarStore.systemState
        }
    }

    /// Filtered grammar points based on current search criteria and filter
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

    /// Whether we should show the search empty state
    var shouldShowSearchEmptyState: Bool {
        grammarPoints.isEmpty &&
            !searchText.isEmpty &&
            effectiveSystemState == .normal
    }

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {
            // Show progress indicator when operation is running
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

    /// Animated loading view to alert user a long async process is currently underway
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

    /// Grammar display dependent on current filter and overall app sync state
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
                showingInspector: $showDetails,
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

    /// Sorting and filtering action toolbar for grammar reference display
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
                Button("TODO: Bulk Import", systemImage: "square.and.arrow.down") {
                    // Nothing yet
                }
                .disabled(true)

                Button("TODO: Bulk Export", systemImage: "square.and.arrow.up") {
                    // Nothing yet
                }
                .disabled(true)

                Divider()

                Button("TODO: Create", systemImage: "rectangle.fill.badge.plus") {
                    // Nothing yet
                }
                .disabled(true)

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

#Preview("Critical Error Postgres") {
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
