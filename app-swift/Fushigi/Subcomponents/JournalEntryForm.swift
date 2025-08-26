//
//  JournalEntryForm.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

// MARK: - Journal Entry Form

import SwiftUI

/// Journal entry form with title, content, and save functionality
struct JournalEntryForm: View {
    /// Journal entry title
    @Binding var entryTitle: String

    /// Journal entry content
    @Binding var entryContent: String

    /// Text selection for grammar tagging
    @Binding var textSelection: TextSelection?

    /// Privacy flag for future social features
    @Binding var isPrivateEntry: Bool

    /// Status message for save operations
    @Binding var statusMessage: String?

    /// Saving state to disable UI during operations
    @Binding var isSaving: Bool

    /// Focus state for title field
    @FocusState private var isTitleFocused: Bool

    /// Focus state for content field
    @FocusState private var isContentFocused: Bool

    /// Save confirmation dialog visibility
    @State private var showSaveConfirmation: Bool = false

    // MARK: - Main View

    var body: some View {
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
                    Text("Are you sure you're ready to submit this entry?")
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

    // MARK: - Helper Methods

    /// Save journal entry to database
    private func saveJournalEntry() async {
        guard !isSaving else { return }

        isSaving = true
        statusMessage = nil
        defer { isSaving = false }

        let result = await submitJournalEntry(
            title: entryTitle,
            content: entryContent,
            isPrivate: isPrivateEntry,
        )

        switch result {
        case let .success(message):
            statusMessage = message
            clearForm()
            print("LOG: Successfully posted journal entry.")
        case let .failure(error):
            statusMessage = "Error: \(error.localizedDescription)"
            print("DEBUG: Failed to post journal entry:", error)
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
}

// MARK: - Previews

#Preview("Entry Form Only") {
    JournalEntryForm(
        entryTitle: .constant("Sample Title"),
        entryContent: .constant("Sample content with some text to show how the editor looks with content."),
        textSelection: .constant(nil),
        isPrivateEntry: .constant(false),
        statusMessage: .constant(nil),
        isSaving: .constant(false),
    )
    .padding()
}

#Preview("Empty Content") {
    JournalEntryForm(
        entryTitle: .constant(""),
        entryContent: .constant(""),
        textSelection: .constant(nil),
        isPrivateEntry: .constant(false),
        statusMessage: .constant(nil),
        isSaving: .constant(false),
    )
    .padding()
}

#Preview("Loading State") {
    JournalEntryForm(
        entryTitle: .constant("My Daily Practice"),
        entryContent: .constant("今日は新しい文法を勉強しました。"),
        textSelection: .constant(nil),
        isPrivateEntry: .constant(true),
        statusMessage: .constant("Saving entry..."),
        isSaving: .constant(true),
    )
    .padding()
}
