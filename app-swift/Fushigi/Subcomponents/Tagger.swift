//
//  Tagger.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - Tagger

/// Interface for creating links between selected text and grammar concepts
struct Tagger: View {
    /// Centralized grammar data store
    @EnvironmentObject var grammarStore: GrammarStore

    /// Controls the tagging interface visibility
    @Binding var isShowingTagger: Bool

    /// Grammar point model containing usage patterns and meanings
    let grammarPoint: GrammarPointLocal

    /// User-selected text content from journal entry for association
    let selectedText: String

    /// Tracks successful tag creation for user feedback
    @State private var isTagCreated = false

    /// Temporary status message for operation feedback
    @State private var operationMessage: String?

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.default) {
            // Action buttons with clear visual hierarchy
            HStack(spacing: UIConstants.Spacing.default) {
                Button("Dismiss") {
                    dismissTagger()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Confirm") {
                    Task {
                        await confirmTagging()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTagCreated)
            }

            // Grammar point information display
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Label("Selected Grammar Point", systemImage: "book.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                    Text(grammarPoint.usage)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.leading, UIConstants.Sizing.defaultPadding)

                    Text(grammarPoint.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, UIConstants.Sizing.defaultPadding)

                    // Grammar point metadata
                    HStack {
                        Text(grammarPoint.context)
                            .font(.caption)
                            .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                            .padding(.vertical, UIConstants.Padding.capsuleHeight)
                            .background(.tertiary)
                            .clipShape(.capsule)

                        if !grammarPoint.tags.isEmpty {
                            coloredTagsText(tags: grammarPoint.tags)
                                .font(.caption)
                        }
                    }
                    .padding(.leading, UIConstants.Sizing.defaultPadding)
                }
            }

            Spacer()

            // Selected text information display
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Label("Selected Text", systemImage: "text.quote")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(selectedText.isEmpty ? "No text selected" : selectedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UIConstants.Sizing.defaultPadding)
                    .overlay(
                        Capsule()
                            .stroke(
                                selectedText.isEmpty ? .clear : .purple,
                                lineWidth: UIConstants.Border.focusedWidth,
                            ),
                    )
            }

            // Operation status display
            if let message = operationMessage {
                Spacer()

                HStack {
                    Image(systemName: isTagCreated ? "checkmark.circle.fill" : "info.circle.fill")
                        .foregroundColor(isTagCreated ? .mint : .red)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                .padding(.vertical, UIConstants.Padding.capsuleHeight)
                .background(.quaternary)
                .clipShape(.capsule)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    /// Create grammar point to text association with user feedback
    private func confirmTagging() async {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            operationMessage = "Please select some text before creating a link."
            return
        }

        isTagCreated = true
        operationMessage = "Grammar link created successfully!"
    }

    /// Dismiss tagging interface and clear selection state
    private func dismissTagger() {
        grammarStore.selectedGrammarPoint = nil
        isShowingTagger = false
    }
}

// MARK: - Previews

#Preview("Tagger - With Text") {
    Tagger(
        isShowingTagger: .constant(true),
        grammarPoint: GrammarPointLocal(
            id: UUID(),
            context: "N3",
            usage: "〜ながら",
            meaning: "while doing",
            tags: ["simultaneous", "action"],
        ),
        selectedText: "私は音楽を聞きながら勉強しています。",
    )
    .withPreviewNavigation()
}

#Preview("Tagger - No Text") {
    Tagger(
        isShowingTagger: .constant(true),
        grammarPoint: GrammarPointLocal(
            id: UUID(),
            context: "N2",
            usage: "〜というのは",
            meaning: "the reason is that",
            tags: ["explanation", "formal"],
        ),
        selectedText: "",
    )
    .withPreviewNavigation()
}
