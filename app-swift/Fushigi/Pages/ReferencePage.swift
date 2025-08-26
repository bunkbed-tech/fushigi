//
//  ReferencePage.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Reference Page

/// Searchable grammar reference interface with detailed grammar point inspection
struct ReferencePage: View {
    /// Responsive layout detection for adaptive table presentation
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Centralized grammar data repository with synchronization capabilities
    @EnvironmentObject var grammarStore: GrammarStore

    /// Currently selected grammar point for detailed examination
    @State private var selectedGrammarID: UUID?

    /// Controls the settings sheet for practice content preferences
    @State private var showingSettings: Bool = false

    /// Controls detailed grammar point inspection interface visibility
    @State private var showingInspector: Bool = false

    /// Search query text coordinated with parent navigation structure
    @Binding var searchText: String

    /// Determines layout strategy based on available horizontal space
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Filtered grammar points based on current search criteria
    var grammarPoints: [GrammarPointLocal] {
        grammarStore.filterGrammarPoints(containing: searchText)
    }

    /// Current primary state for UI rendering decisions
    var systemState: SystemState {
        grammarStore.systemState
    }

    // MARK: - Main View

    var body: some View {
        Group {
            // TODO: Figure out better ux for proper error views
            switch systemState {
            case .loading, .emptyData, .criticalError:
                systemState.contentUnavailableView {
                    if case .emptyData = systemState {
                        searchText = ""
                    }
                    await grammarStore.refresh()
                }
            case .normal, .degradedOperation:
                if grammarPoints.isEmpty, !searchText.isEmpty, !grammarStore.grammarItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    GrammarTable(
                        selectedGrammarID: $selectedGrammarID,
                        showingInspector: $showingInspector,
                        grammarPoints: grammarPoints,
                        isCompact: isCompact,
                        onRefresh: {
                            await grammarStore.refresh()
                        },
                    )
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Menu("Options", systemImage: "ellipsis.circle") {
                    Button("Import Grammar", systemImage: "square.and.arrow.down") {
                        // TODO: Implement grammar import functionality
                    }
                    .disabled(true)

                    Button("Export Study List", systemImage: "square.and.arrow.up") {
                        // TODO: Implement grammar export functionality
                    }
                    .disabled(true)

                    Divider()

                    Button("Delete All", systemImage: "trash", role: .destructive) {
                        // TODO: Implement bulk delete with confirmation
                    }
                    .disabled(true)
                }
            }
        }
        .sheet(
            isPresented: $showingInspector,
            onDismiss: {
                selectedGrammarID = nil
            },
            content: {
                if let selectedGP = grammarStore.selectedGrammarPoint {
                    DetailedGrammar(
                        isPresented: $showingInspector,
                        grammarPoint: selectedGP,
                    )
                    .presentationDetents([.medium, .large], selection: .constant(.medium))
                } else {
                    ContentUnavailableView {
                        Label("Error", systemImage: "xmark.circle")
                    } description: {
                        Text("Selected grammarID is null. Log bug.")
                    } actions: {
                        Button("Dismiss") {
                            showingInspector = false
                        }
                    }
                    .presentationDetents([.medium])
                }
            },
        )
        .background {
            LinearGradient(
                colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Degraded Operation Postgres") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .postgresError)
}

#Preview("Degraded Operation SwiftData") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .swiftDataError)
}

#Preview("With Search Results") {
    ReferencePage(searchText: .constant("Hello"))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("No Search Results") {
    ReferencePage(searchText: .constant("nonexistent"))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Loading State") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading, systemHealth: .healthy)
}

#Preview("Empty Database") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .healthy)
}

#Preview("Critical Error Postgres") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .postgresError)
}

#Preview("Critical Error SwiftData") {
    ReferencePage(searchText: .constant(""))
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}
