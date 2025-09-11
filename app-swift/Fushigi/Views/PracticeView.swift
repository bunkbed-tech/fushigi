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

    /// Centralized sentence tag repository with synchronization capabilities
    @EnvironmentObject var sentenceStore: SentenceStore

    /// Centralized journal entry repository with synchronization capabilities
    @EnvironmentObject var journalStore: JournalStore

    /// Focus state for title field
    @FocusState private var isTitleFocused: Bool

    /// Focus state for content field
    @FocusState private var isContentFocused: Bool

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

    /// Save confirmation dialog visibility
    @State private var showSaveConfirmation: Bool = false

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

    /// SRS records based on current sourcing mode
    private var currentRecords: [SRSRecordLocal] {
        studyStore.srsStore.getSRSRecords(for: selectedSource)
    }

    /// Grammar points matching SRS records base on current sourcing mode
    private var currentGrammar: [GrammarPointLocal] {
        studyStore.inSRSGrammarItems.filter { grammarPoint in
            currentRecords.contains(where: { $0.grammar == grammarPoint.id })
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
                    currentGrammar: currentGrammar
                )

                entryForm.layoutPriority(1)

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

    /// Save journal entry to database
    private func saveJournalEntry() async {
        guard !isSaving else { return }

        isSaving = true
        statusMessage = nil
        defer { isSaving = false }

        let result = await journalStore.createEntry(
            title: entryTitle,
            content: entryContent,
            isPrivate: isPrivateEntry,
            sentenceStore: sentenceStore,
        )

        switch result {
        case let .success(message):
            statusMessage = message
            clearForm()
            print("LOG: Successfully posted journal entry.")
        case let .failure(error):
            statusMessage = "Error: \(error.localizedDescription)"
            print("ERROR: Failed to post journal entry:", error)
        }
    }

    /// Clear form after successful submission
    private func clearForm() {
        textSelection = nil // must clear textSelection first to be safe from index crash
        entryTitle = ""
        entryContent = ""
        isPrivateEntry = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            statusMessage = ""
        }
    }

    /// Temporarily add tag to list to be processed later after Journal submission, with slight delay to improve UX
    private func tagSelectedText(with grammarPoint: GrammarPointLocal) async {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Error: Please select some text before creating a link."
            return
        }

        let result = await sentenceStore.addPendingTag(
            grammar: grammarPoint.id,
            selectedText: selectedText
        )

        switch result {
        case .success:
            statusMessage = "Sentence tag successfully queued"
        case .failure:
            statusMessage = "Error: Sentence tag failed to queue"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = nil
        }
    }

    // MARK: - Sub Views

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

    /// Content of the tagging sheet, showing a list of all current tags for a given grammar item as well as the currently
    /// selected text. A fall back ContentUnavailableView is also provided, but this should never happen unless a bug
    /// has surfaced.
    @ViewBuilder
    private var taggerView: some View {
        if let grammarPoint = studyStore.grammarStore.selectedGrammarPoint {
            Tagger(
                statusMessage: $statusMessage,
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

    @ViewBuilder
    private var entryForm: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Title").font(.headline)
                TextField("Enter title", text: $entryTitle)
                    .padding(UIConstants.Spacing.row)
                    .textFieldStyle(.plain)
                    .overlay(
                        RoundedRectangle(cornerSize: UIConstants.Sizing.cornerRadius)
                            .stroke(
                                isTitleFocused ? .purple : .primary,
                                lineWidth: UIConstants.Border.width,
                            ),
                    )
                    .focused($isTitleFocused)
                    .onSubmit {
                        isContentFocused = true
                        isTitleFocused = false
                    }
                    .disabled(isSaving)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Content").font(.headline)
                ZStack(alignment: .topLeading) {
                    if entryContent.isEmpty {
                        Text("Use grammar points above to write a journal entry!")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    TextEditor(text: $entryContent, selection: $textSelection)
                        .scrollContentBackground(.hidden)
                        .toolbar{
                            keyboardQuickTagger
                        }
                }
                .frame(minHeight: UIConstants.Sizing.contentMinHeight, maxHeight: .infinity)
                .padding(UIConstants.Spacing.row)
                .overlay(
                    RoundedRectangle(cornerSize: UIConstants.Sizing.cornerRadius)
                        .stroke(
                            isContentFocused ? .purple : .primary,
                            lineWidth: UIConstants.Border.width,
                        ),
                )
                .focused($isContentFocused)
                .disabled(isSaving)
                .layoutPriority(1) // TODO: figure out why autoresize wont work
            }

            // Privacy toggle
            Toggle("Private Entry", isOn: $isPrivateEntry)
                .disabled(isSaving)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Save section
            HStack(alignment: .center) {
                Button {
                    showSaveConfirmation = true
                } label: {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Save").bold()
                    }
                }
                .confirmationDialog("Confirm Submission", isPresented: $showSaveConfirmation) {
                    Button("Confirm") {
                        Task {
                            await saveJournalEntry()
                        }
                    }
                } message: {
                    Text("Are you sure you're ready to submit this entry? \(sentenceStore.pendingSentences.count) tags will be added.")
                }
                .disabled(isSaving)
                .buttonStyle(.borderedProminent)
                .dialogIcon(Image(systemName: "questionmark.circle"))

                if let message = statusMessage {
                    Text(message)
                        .foregroundColor(message.hasPrefix("Error") ? .red : .green)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var keyboardQuickTagger: some ToolbarContent {
        // Keyboard mobile tagger (also shows up on mac touch bar)
        ToolbarItem (placement: .keyboard) {
            // Only show grammar tagging buttons if text is selected
            if !selectedText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UIConstants.Spacing.row) {
                        ForEach(currentGrammar, id: \.id) { grammarPoint in
                            Button(grammarPoint.usage) {
                                Task {
                                    await tagSelectedText(with: grammarPoint)
                                    textSelection = nil // unselect text
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            } else if statusMessage != nil {
                Text(statusMessage!)
                    .foregroundColor(statusMessage!.hasPrefix("Error") ? .red : .mint)
                    .font(.caption)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Previews

#Preview("Normal State") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores()
}

#Preview("Degraded Operation Postgres") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Degraded Operation SwiftData") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(systemHealth: .swiftDataError)
}

#Preview("Loading State") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .loading)
}

#Preview("Empty Data") {
    PracticeView()
        .withPreviewNavigation()
        .withPreviewStores(dataAvailability: .empty)
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

