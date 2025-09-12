//
//  PracticeView.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import SwiftUI

// MARK: - Practice View

/// The central user view of the app, first showing up after sign in and authorization. It shows a list of suggested
/// study items for the day (SRS influenced) with basic filtering to influence the SRS, as well as a form to actually
/// write the journal entry.
struct PracticeView: View {
    // MARK: - Published State

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @EnvironmentObject var studyStore: StudyStore
    @EnvironmentObject var sentenceStore: SentenceStore
    @EnvironmentObject var journalStore: JournalStore

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool

    @State private var showSettings = false
    @State private var showTagger = false
    @State private var showDetails = false
    /// User preference for politeness level filtering (friends, bosses, customers, etc.)
    @State private var selectedLevel: Level = .all
    /// User preference for usage context filtering (spoken, written, ancient, business, etc.)
    @State private var selectedContext: Context = .all
    /// User preference for language variants and regional dialects (slang, onomatope, etc.)
    @State private var selectedLanguageVariant: LanguageVariants = .none
    /// User preference for grammar sourcing algorithm (random vs. SRS)
    @State private var selectedSource: SourceMode = .random
    @State private var entryTitle = ""
    @State private var entryContent = ""
    @State private var isPrivateEntry = false
    /// Text selection capture from journal content to let users highlight explicitly grammar usage and tag it to the
    /// current journal entry once they submit. This is just the TextSelection object which is not the same as a
    /// String which must be calculated later and properly error handled.
    @State private var textSelection: TextSelection?
    @State private var statusMessage: String?
    @State private var isSaving = false
    @State private var showSaveConfirmation: Bool = false

    // MARK: - Computed Properties

    /// Flag to get iPadOS to utilize iOS features vs MacOS features based on window size
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    /// Determine the health of the most important store for this view (SRS), whether it's an error state,
    /// loading state, or healthy state
    private var systemState: SystemState {
        studyStore.srsStore.systemState
    }

    /// Because TextSelection objects do not behave like strings and track selected indices, we must extract
    /// readable text in the string format in order to add it to sentence tags when the user submits a journal entry
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

    /// All daily study items are determined based off SRS records whether the active source is SRS or random in order
    /// to keep things general
    private var currentRecords: [SRSRecordLocal] {
        studyStore.srsStore.getSRSRecords(for: selectedSource)
    }

    /// From the current records computed property, filter for grammar points matching SRS records base on current
    /// sourcing mode in order to aide in UI/UX decisions as well as Sentence record creation when sending user
    /// data to PocketBase
    private var currentGrammar: [GrammarPointLocal] {
        studyStore.inSRSGrammarItems.filter { grammarPoint in
            currentRecords.contains(where: { $0.grammar == grammarPoint.id })
        }
    }

    // MARK: - Main View

    var body: some View {
        GeometryReader { screen in
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.default) {
                    DailyGrammar(
                        showTagger: $showTagger,
                        showDetails: $showDetails,
                        selectedSource: $selectedSource,
                        currentGrammar: currentGrammar,
                    )

                    entryForm(availableHeight: screen.size.height)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
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
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
            ToolbarItem {
                Button("Practice Settings", systemImage: "graduationcap") { showSettings.toggle() }
                    .disabled(!entryContent.isEmpty)
            }
            ToolbarItem {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await refreshGrammarPoints() } }
                    .disabled(!entryContent.isEmpty)
            }
            // keyboardQuickTagger
        }
    }

    // MARK: - Helper Methods

    /// Refreshes grammar points based on current source setting, SRS or random. This user interaction can
    /// be run as many times as desired unless there are active tags waiting to be loaded to the database or
    /// content currently in the journal entry form. This is done to discourage switching around the days
    /// current study suggestions mid session.
    private func refreshGrammarPoints() async {
        studyStore.srsStore.forceDailyRefresh(currentMode: selectedSource)
        showSettings = false
    }

    /// Save journal entry to database by first post the entry itself, grabbing the auto generated id, and
    /// attaching it to every pending sentence tag to post to the database as well. This results in two
    /// post calls to the network as well as two full refresh sequences. As data is accumulated, I am
    /// curious if this ends up being a bottleneck.
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

    /// Clear form after successful submission to allow user to conduct further study sessions back from square one. A
    /// forced wait is currently implemented in order to allow any currently active error messages to linger on screen long
    /// enough to be read by the user.
    private func clearForm() {
        textSelection = nil // must clear textSelection first to be safe from index crash
        entryTitle = ""
        entryContent = ""
        isPrivateEntry = false
        sentenceStore.pendingSentences.removeAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            statusMessage = ""
        }
    }

    /// Temporarily add tag to list to be processed later after Journal submission, with slight delay to improve UX.
    /// This is done so users can build a pending list of items and send them once they are ready. Thus, they can
    /// also delete the tags before posting the journal entry if they change their mind mid session.
    private func tagSelectedText(with grammarPoint: GrammarPointLocal) async {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Error: Please select some text before creating a link."
            return
        }

        let result = await sentenceStore.addPendingTag(
            grammar: grammarPoint.id,
            selectedText: selectedText,
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

    /// Settings is a popup sheet that allows users to change the active study mode or some basic filters in order
    /// to influence the algorithm choosing the daily suggested study items. This is done in case users want to focus
    /// on a specific tag such as slang, business, written sentence patterns.
    @ViewBuilder
    private var settingsView: some View {
        GrammarSettings(
            selectedLevel: $selectedLevel,
            selectedContext: $selectedContext,
            selectedLanguageVariant: $selectedLanguageVariant,
            selectedSource: $selectedSource,
        )
    }

    /// Content of the tagging sheet, showing a list of all current tags for a given grammar item as well as the
    /// currently selected text. A fall back ContentUnavailableView is also provided, but this should never happen
    /// unless a bug has surfaced.
    @ViewBuilder
    private var taggerView: some View {
        if let grammarPoint = studyStore.grammarStore.selectedGrammarPoint {
            Tagger(
                statusMessage: $statusMessage,
                showTagger: $showTagger,
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

    /// Resizable entry form where the diary content should resize to fill all remaining size on device. Requires a
    /// title and content before submit will work. When users select text, they are able to log Sentences in the
    /// database that connect Journal Entry to Grammar to Sentence. These tags are eventually formally submitted
    /// to the backend once the user submits the form.
    ///
    /// TODO: Get the TextEditor to auto size to the available screen size remainder
    /// TODO: Make sure that when long entries are typed instead of growing, it scrolls
    @ViewBuilder
    private func entryForm(availableHeight: CGFloat) -> some View {
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
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $entryContent, selection: $textSelection)
                        .scrollContentBackground(.hidden)
                        .focused($isContentFocused)
                        .disabled(isSaving)
                }
                .frame(minHeight: availableHeight * 0.4, maxHeight: .infinity)
                .padding(UIConstants.Spacing.row)
                .overlay(
                    RoundedRectangle(cornerSize: UIConstants.Sizing.cornerRadius)
                        .stroke(
                            isContentFocused ? .purple : .primary,
                            lineWidth: UIConstants.Border.width,
                        ),
                )
            }

            Toggle("Private Entry", isOn: $isPrivateEntry)
                .disabled(isSaving)
                .frame(maxWidth: .infinity, alignment: .leading)

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
                    Text(
                        "Are you sure you're ready to submit this entry? \(sentenceStore.pendingSentences.count) tags will be added.",
                    )
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

    /// A handy keyboard toolbar for iOS and MacOS touch bar devices that show a list of available tags (grammar points
    /// in today's study list) that can be attached to the currently selected sentence.
    ///
    /// It currently does not work due to what I'm assuming is an obscure SwiftUI bug. The .keyboard
    /// ToolbarItemPlacement does not reactively update until the entire view is refreshed such as by opening a sheet or
    /// navigating to another tab. This behavior is not experienced with any other ToolbarItemPlacement.
    ///
    /// Bug Report: https://stackoverflow.com/questions/79728378/
    @ToolbarContentBuilder
    private var keyboardQuickTagger: some ToolbarContent {
        // Keyboard mobile tagger (also shows up on mac touch bar)
        ToolbarItemGroup(placement: .keyboard) {
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
