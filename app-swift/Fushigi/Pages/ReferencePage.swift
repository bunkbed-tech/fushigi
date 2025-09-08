//
//  ReferencePage.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Bulk Operation State

enum BulkOperationState: Equatable {
    case idle
    case running
    case success(String)
    case error(String)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var shouldDisableUI: Bool {
        if case .running = self { return true }
        return false
    }
}

// MARK: - Reference Page

enum GrammarQuickFilter: String, CaseIterable {
    case all = "All Grammar"
    case defaults = "Default Items"
    case custom = "Custom Items"
    case inSRS = "Added To SRS"
    case available = "Not Yet Added"

    /// Whether this filter requires SRS data
    var requiresSRSData: Bool {
        switch self {
        case .inSRS:
            true
        case .all, .defaults, .custom, .available:
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

    /// BETTER: Track bulk operation state with non-dismissible progress
    @State private var bulkOperationState: BulkOperationState = .idle

    /// Search query text coordinated with parent navigation structure
    @Binding var searchText: String

    #if DEBUG
    // Convenience init for previews to seed @State values
    init(
        searchText: Binding<String>,
        initialBulkOperationState: BulkOperationState = .idle
    ) {
        self._searchText = searchText
        self._bulkOperationState = State(initialValue: initialBulkOperationState)
    }
    #endif

    /// Determines layout strategy based on available horizontal space
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Computed system state based on current filter
    var effectiveSystemState: SystemState {
        if selectedFilter.requiresSRSData {
            // For SRS-dependent filters, check SRS state first, then fall back to grammar state
            switch srsStore.systemState {
            case .emptySRS, .emptyData:
                .emptySRS
            case .loading, .normal, .degradedOperation, .criticalError:
                srsStore.systemState
            }
        } else {
            // For grammar-only filters, use grammar store state
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
            effectiveSystemState == .normal &&
            hasDataForCurrentFilter
    }

    /// Whether the current filter has underlying data available
    var hasDataForCurrentFilter: Bool {
        if selectedFilter.requiresSRSData {
            return !srsStore.srsRecords.isEmpty
        } else {
            if selectedFilter == .custom {
                return !grammarStore.userGrammarItems.isEmpty
            }
            return !grammarStore.grammarItems.isEmpty
        }
    }

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {
            // Show progress indicator when operation is running
            if bulkOperationState.isRunning {
                bulkOperationProgressView
            }

            mainContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // necessary for empty search
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
                .disabled(bulkOperationState.shouldDisableUI)
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
    private var bulkOperationProgressView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Adding default items to SRS list...")
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
                onRefresh: {
                    guard !bulkOperationState.shouldDisableUI else { return }
                    await studyStore.refresh()
                },
            )
        } else if !hasDataForCurrentFilter {
            ContentUnavailableView {
                Label("No \(selectedFilter.rawValue)", systemImage: "tray")
            } description: {
                Text("Try adding new grammar points or changing the filter.")
                    .foregroundColor(.secondary)
            }
        } else if shouldShowSearchEmptyState {
            ContentUnavailableView.search(text: searchText)
        } else {
            GrammarTable(
                selectedGrammarID: $selectedGrammarID,
                showingInspector: $showingInspector,
                grammarPoints: grammarPoints,
                isCompact: isCompact,
                onRefresh: {
                    guard !bulkOperationState.shouldDisableUI else { return }
                    await studyStore.refresh()
                },
            )
            .disabled(bulkOperationState.shouldDisableUI)
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
            .disabled(bulkOperationState.shouldDisableUI)

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
                    BulkSaveButton(
                        items: studyStore.availableGrammarItems,
                        operationState: $bulkOperationState,
                        onExecute: { items in
                            await srsStore.addBulkToSRS(items)
                        }
                    )
                }
            }
            .disabled(bulkOperationState.shouldDisableUI)
        }
    }

    @ViewBuilder
    private var grammarInspectorSheet: some View {
        if let point = grammarStore.selectedGrammarPoint {
            GrammarDetailSheet(
                point: point,
                isInSRS: srsStore.isInSRS(point.id),
                isDefault: grammarStore.isDefaultGrammar(point),
                onDismiss: { showingInspector = false },
            )
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
}

// MARK: - BETTER: Reusable Bulk Save Button Component

struct BulkSaveButton<T>: View {
    let items: [T]
    @Binding var operationState: BulkOperationState
    let onExecute: ([T]) async -> BulkOperationResult

    var body: some View {
        Button(action: executeBulkOperation) {
            HStack {
                Text("Bulk Save Defaults")

                switch operationState {
                case .idle:
                    Image(systemName: "rectangle.stack.fill.badge.plus")
                case .running:
                    ProgressView()
                        .scaleEffect(0.7)
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .disabled(items.isEmpty || operationState.shouldDisableUI)
        .onChange(of: operationState) { _, newState in
            if case .success = newState {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if case .success = operationState {
                        operationState = .idle
                    }
                }
            } else if case .error = newState {
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    if case .error = operationState {
                        operationState = .idle
                    }
                }
            }
        }
    }

    private func executeBulkOperation() {
        Task {
            operationState = .running

            let result = await onExecute(items)

            // CLEAN: Handle unified result type
            switch result {
            case .success(let success):
                operationState = .success(success.message)
            case .failure(let error):
                operationState = .error(error.message)
            }
        }
    }
}

// MARK: - Grammar Detail Sheet

/// Cross-platform grammar detail sheet that handles iOS vs macOS presentation
struct GrammarDetailSheet: View {
    let point: GrammarPointLocal
    let isInSRS: Bool
    let isDefault: Bool
    let onDismiss: () -> Void

    var body: some View {
        PlatformSheet(title: "Grammar Details", onDismiss: onDismiss) {
            grammarContent
        }
        #if os(macOS)
        .frame(minWidth: UIConstants.Sizing.forcedFrameWidth, minHeight: UIConstants.Sizing.forcedFrameHeight)
        #else
        .presentationDetents([.medium, .large], selection: .constant(.medium))
        #endif
    }

    @ViewBuilder
    private var grammarContent: some View {
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
                            print("TODO: Implement add to SRS")
                        }
                        .disabled(true)
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

#Preview("Empty SRS") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(systemState: .emptySRS)
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

#Preview("Bulk Operation Running") {
    ReferencePage(
        searchText: .constant(""),
        initialBulkOperationState: .running
    )
    .withPreviewNavigation()
    .withPreviewStores()
}

#Preview("Bulk Operation Success") {
    ReferencePage(
        searchText: .constant(""),
        initialBulkOperationState: .success("Added 25 items to study list")
    )
    .withPreviewNavigation()
    .withPreviewStores()
}

#Preview("Bulk Operation Error") {
    ReferencePage(
        searchText: .constant(""),
        initialBulkOperationState: .error("Network error - please try again")
    )
    .withPreviewNavigation()
    .withPreviewStores()
}
