//
//  ReferencePage.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Reference Page

enum GrammarQuickFilter: String, CaseIterable {
    case all = "All"
    case defaults = "Default"
    case custom = "Custom"
    case inSRS = "SRS"
    case available = "Available"

    /// Whether this filter requires SRS data
    var requiresSRSData: Bool {
        switch self {
        case .inSRS, .available:
            true
        case .all, .defaults, .custom:
            false
        }
    }
}

/// Searchable grammar reference interface with detailed grammar point inspection
struct ReferencePage: View {
    /// Responsive layout detection for adaptive table presentation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Centralized on-device storage for user's grammar points (used for application state)
    @EnvironmentObject var grammarStore: GrammarStore

    /// Centralized on-device storage for user's srs records
    @EnvironmentObject var srsStore: SRSStore

    /// Currently selected grammar point for detailed examination
    @State private var selectedGrammarID: String?

    /// Controls detailed grammar point inspection interface visibility
    @State private var showingInspector: Bool = false

    /// Controls currently displayed source of grammar
    @State private var selectedFilter: GrammarQuickFilter = .all

    /// Search query text coordinated with parent navigation structure
    @Binding var searchText: String

    /// Determines layout strategy based on available horizontal space
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Computed system state based on current filter
    var effectiveSystemState: SystemState {
        if selectedFilter.requiresSRSData {
            srsStore.systemState
        } else {
            grammarStore.systemState
        }
    }

    /// Filtered grammar points based on current search criteria and filter
    var grammarPoints: [GrammarPointLocal] {
        let baseItems: [GrammarPointLocal] = switch selectedFilter {
        case .all:
            grammarStore.grammarItems
        case .defaults:
            grammarStore.systemGrammarItems
        case .custom:
            grammarStore.userGrammarItems
        case .inSRS:
            studyStore.inSRSGrammarItems
        case .available:
            studyStore.availableGrammarItems
        }

        return grammarStore.filterGrammarPoints(for: baseItems, containing: searchText)
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
        .sheet(isPresented: $showingInspector, onDismiss: {
            selectedGrammarID = nil
        }) {
            grammarInspectorSheet
        }
    }

    // MARK: - View Components

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
                selectedGrammarID: $selectedGrammarID,
                showingInspector: $showingInspector,
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
                            await srsStore.addBulkToSRS(studyStore.availableGrammarItems)
                        }
                    }
                    .disabled(studyStore.availableGrammarItems.isEmpty)
                }
            }
            .disabled(effectiveSystemState.shouldDisableUI)
        }
    }

    @ViewBuilder
    private var grammarInspectorSheet: some View {
        if let point = grammarStore.selectedGrammarPoint {
            PlatformSheet(title: "Grammar Details", onDismiss: { showingInspector = false }) {
                grammarContent(
                    point: point,
                    isInSRS: srsStore.isInSRS(point.id),
                    isDefault: grammarStore.isDefaultGrammar(point),
                )
            }
            #if os(macOS)
            .frame(minWidth: UIConstants.Sizing.forcedFrameWidth, minHeight: UIConstants.Sizing.forcedFrameHeight)
            #else
            .presentationDetents([.medium, .large], selection: .constant(.medium))
            #endif
        } else {
            ContentUnavailableView {
                Label("Error", systemImage: "xmark.circle")
            } description: {
                Text("Selected grammar is null. Please report this bug.")
            } actions: {
                Button("Dismiss") {
                    showingInspector = false
                }
                .buttonStyle(.borderedProminent)
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private func grammarContent(point: GrammarPointLocal, isInSRS: Bool, isDefault: Bool) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            Text("Usage: \(point.usage)")
            Text("Meaning: \(point.meaning)")
            Divider()
            coloredTagsText(tags: point.tags)
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    if isInSRS {
                        Button("Remove from SRS", systemImage: "rectangle.on.rectangle.slash") {
                            print("TODO: Implement remove from SRS")
                        }
                        .disabled(true)
                    } else {
                        Button("Add to SRS", systemImage: "plus.rectangle.on.rectangle") {
                            Task {
                                await srsStore.addToSRS(point.id)
                            }
                        }
                    }

                    if !isDefault {
                        Button("Edit", systemImage: "square.and.arrow.up.fill") {
                            print("TODO: Implement editing user grammar point...")
                        }
                        .disabled(true)

                        Button("Delete", systemImage: "trash.slash") {
                            print("TODO: Implement removing user grammar point...")
                        }
                        .disabled(true)
                    }
                }
                .labelStyle(.iconOnly)
                .disabled(effectiveSystemState.shouldDisableUI)
            }
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Degraded Operation Postgres") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .swiftDataError)
}

#Preview("With Search Results") {
    ReferencePage(searchText: .constant("Hello"))
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("No Search Results") {
    ReferencePage(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Loading State") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Empty Database") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty)
}

#Preview("Critical Error Postgres") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .pocketbaseError)
}

#Preview("Critical Error SwiftData") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}

#Preview("Missing SRS") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(noSRS: true)
}
