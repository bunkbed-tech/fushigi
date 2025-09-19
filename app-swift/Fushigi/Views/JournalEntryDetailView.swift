//
//  JournalEntryDetailView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/19.
//

import SwiftUI

// MARK: - Journal Entry Detail View

/// Displays detailed view of a selected journal entry including content, tagged grammar points, and AI feedback.
/// This view shows in the detail column on iPad/Mac or as a sheet on iPhone when a journal entry is selected.
struct JournalEntryDetailView: View {
    // MARK: - Published State

    @EnvironmentObject var studyStore: StudyStore
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editIsPrivate = false

    // MARK: - Init

    let journalEntry: JournalEntryLocal

    // MARK: - Main View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Entry" : journalEntry.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }

            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var displayView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            // Header with title and metadata
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                HStack {
                    Text(journalEntry.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    if journalEntry.isPrivate {
                        Label("Private", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(journalEntry.created.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Content
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Content")
                    .font(.headline)
                    .foregroundStyle(.mint)

                Text(journalEntry.content)
                    .font(.body)
            }

            Divider()

            // Grammar points used (from sentence store)
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Grammar Points")
                    .font(.headline)
                    .foregroundStyle(.mint)

                let sentences = studyStore.getSentencesForGrammar(journalEntry.id)
                if sentences.isEmpty {
                    Text("No grammar points tagged for this entry")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(sentences, id: \.id) { sentence in
                        if let grammarPoint = studyStore.grammarStore.grammarItems.first(where: { $0.id == sentence.grammar }) {
                            HStack {
                                Text("•")
                                Text(grammarPoint.usage)
                                Spacer()
                                Text(sentence.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            // AI Feedback placeholder
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("AI Feedback")
                    .font(.headline)
                    .foregroundStyle(.purple)

                Text("(Placeholder) AI feedback functionality coming soon. This will analyze your writing and provide grammar suggestions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var editingView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Title")
                    .font(.headline)

                TextField("Entry title", text: $editTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Text("Content")
                    .font(.headline)

                TextEditor(text: $editContent)
                    .frame(minHeight: 200)
                    .padding(UIConstants.Spacing.row)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius.width)
                            .stroke(.primary, lineWidth: 1)
                    )
            }

            Toggle("Private Entry", isOn: $editIsPrivate)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func startEditing() {
        editTitle = journalEntry.title
        editContent = journalEntry.content
        editIsPrivate = journalEntry.isPrivate
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
        editTitle = ""
        editContent = ""
        editIsPrivate = false
    }

    private func saveChanges() {
        // TODO: Implement journal entry update functionality
        print("LOG: Saving changes to journal entry: \(journalEntry.id)")
        print("LOG: New title: \(editTitle)")
        print("LOG: New content: \(editContent)")
        print("LOG: New privacy: \(editIsPrivate)")

        isEditing = false
    }
}
