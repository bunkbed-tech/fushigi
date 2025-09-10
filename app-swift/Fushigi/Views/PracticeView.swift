//
//  PracticeView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Practice View

/// View for creating journal entries with targeted grammar point integration
struct PracticeView: View {
    // MARK: - Published State

    /// Responsive layout helper for switching between iOS/side-split apps and iPadOS/macOS layouts
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Controls the settings sheet for practice content preferences
    @State private var showSettings = false

    /// Controls the tagging sheet for grammar point and sentence relationships
    @State private var showTagger = false

    /// Controls detailed grammar point inspection interface visibility
    @State private var showDetails = false

    /// User preference for politeness level filtering
    @State private var selectedLevel: Level = .all

    /// User preference for usage context filtering
    @State private var selectedContext: Context = .all

    /// User preference for language variants and regional dialects
    @State private var selectedLanguageVariant: LanguageVariants = .none

    /// User preference for grammar sourcing algorithm
    @State private var selectedSource: SourceMode = .random

    /// User-entered title for the current journal entry
    @State private var entryTitle = ""

    /// Main content of the journal entry where users practice grammar usage
    @State private var entryContent = ""

    /// Text selection capture from journal content for grammar point association
    @State private var textSelection: TextSelection?

    /// Privacy flag for future social features and content sharing
    @State private var isPrivateEntry = false

    /// User-visible message for displaying operation results and feedback
    @State private var statusMessage: String?

    /// Loading state flag to disable UI elements during async operations
    @State private var isSaving = false

    // MARK: - Computed Properties

    /// Determines layout strategy based on available horizontal space
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// All daily grammar items are taken from SRS records no matter if they are algorithmic or random
    private var systemState: SystemState {
        studyStore.srsStore.systemState
    }

    /// Extracts readable text from TextSelection objects for tagging
    private var selectedText: String {
        guard let selection = textSelection, !selection.isInsertion else { return "" }

        switch selection.indices {
        case let .selection(range):
            return String(entryContent[range])
        case let .multiSelection(ranges):
            return ranges.ranges.map { String(entryContent[$0]) }.joined(separator: "\n")
        @unknown default:
            print("ERROR: PracticeView: TextSelection: unknown case: \(selection.indices)")
            return ""
        }
    }

    // MARK: - Main View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing:
                UIConstants.Spacing.default)
            {
                DailyGrammar(
                    showTagger: $showTagger,
                    showDetails: $showDetails,
                    selectedSource: $selectedSource,
                )

                JournalEntryForm(
                    entryTitle: $entryTitle,
                    entryContent: $entryContent,
                    textSelection: $textSelection,
                    isPrivateEntry: $isPrivateEntry,
                    statusMessage: $statusMessage,
                    isSaving: $isSaving,
                )
                .layoutPriority(1)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showSettings) {
            if isCompact {
                settingsView
                    .presentationDetents([.medium, .large])
            } else {
                settingsView
            }
        }
        .sheet(isPresented: $showTagger, onDismiss: {
            studyStore.grammarStore.selectedGrammarPoint = nil
        }) {
            if isCompact {
                taggerView.presentationDetents([.medium, .large])
            } else {
                taggerView
            }
        }
        .sheet(isPresented: $showDetails, onDismiss: {
            studyStore.grammarStore.selectedGrammarPoint = nil
        }) {
            GrammarInspector(
                showDetails: $showDetails,
                systemState: systemState,
            )
        }
        .toolbar {
            ToolbarItem {
                Button("Practice Settings", systemImage: "graduationcap") { showSettings.toggle() }
                    .disabled(!entryContent.isEmpty)
            }
            ToolbarItem {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await refreshGrammarPoints() } }
                    .disabled(!entryContent.isEmpty)
            }
        }
    }

    // MARK: - Helper Methods

    /// Refreshes grammar points based on current source setting
    private func refreshGrammarPoints() async {
        studyStore.srsStore.forceDailyRefresh(currentMode: selectedSource)
        showSettings = false
    }

    /// Settings configuration view with state management
    @ViewBuilder
    private var settingsView: some View {
        GrammarSettings(
            selectedLevel: $selectedLevel,
            selectedContext: $selectedContext,
            selectedLanguageVariant: $selectedLanguageVariant,
            selectedSource: $selectedSource,
        )
    }

    @ViewBuilder
    private var taggerView: some View {
        if let grammarPoint = studyStore.grammarStore.selectedGrammarPoint {
            Tagger(
                isShowingTagger: $showTagger,
                grammarPoint: grammarPoint,
                selectedText: selectedText,
            )
        } else {
            ContentUnavailableView {
                Label("Grammar Point Unavailable", systemImage: "xmark.circle")
            } description: {
                Text(
                    "The selected grammar point id is nil." +
                        "Please try selecting another point.",
                )
            } actions: {
                Button("Dismiss") {
                    showTagger = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("Degraded Operation Postgres") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .available, systemHealth: .swiftDataError)
}

#Preview("Loading State") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading, systemHealth: .healthy)
}

#Preview("Empty Data") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .healthy)
}

#Preview("Critical Error PocketBase") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .pocketbaseError)
}

#Preview("Critical Error SwiftData") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty, systemHealth: .swiftDataError)
}

#Preview("Missing SRS") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(noSRS: true)
}
