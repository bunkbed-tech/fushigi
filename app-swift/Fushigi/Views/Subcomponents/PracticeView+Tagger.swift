//
//  PracticeView+Tagger.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

/// Interface for creating links between selected text and grammar concepts
struct Tagger: View {
    // MARK: - Published State

    /// Centralized grammar data store
    @EnvironmentObject var grammarStore: GrammarStore

    /// Centralized sentence tag data store
    @EnvironmentObject var sentenceStore: SentenceStore

    /// Temporary status message for operation feedback
    @Binding var statusMessage: String?

    /// Controls the tagging interface visibility
    @Binding var isShowingTagger: Bool

    // MARK: - Computed Properties

    /// Tracks successful tag creation for user feedback
    private var pendingTags: [SentenceCreate] {
        sentenceStore.pendingSentences.filter { $0.grammar == grammarPoint.id }
    }

    // MARK: - Init

    /// Grammar point model containing usage patterns and meanings
    let grammarPoint: GrammarPointLocal

    /// User-selected text content from journal entry for association
    let selectedText: String

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.default) {
            // Action buttons with clear visual hierarchy
            HStack(spacing: UIConstants.Spacing.default) {
                Button("Dismiss") { dismissTagger() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Confirm") { Task { await confirmTagging() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Selected text display
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Label("Selected Text", systemImage: "text.quote")
                    .font(.headline)

                Text(selectedText.isEmpty ? "No text selected" : selectedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UIConstants.Sizing.defaultPadding)
                    .overlay(
                        Capsule().stroke(
                            selectedText.isEmpty ? .clear : .purple,
                            lineWidth: UIConstants.Border.focusedWidth,
                        ),
                    )

                if !pendingTags.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: UIConstants.Spacing.row) {
                            ForEach(pendingTags, id: \.id) { tag in
                                HStack {
                                    Text(tag.content)
                                    Spacer()
                                    Button("Delete") {
                                        sentenceStore.removePendingTag(content: tag.content, grammar: grammarPoint.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: UIConstants.Sizing.forcedFrameHeight)
                    .scrollIndicators(.visible)
                }
            }

            Spacer()

            // Status message (unchanged)
            if let message = statusMessage {
                HStack {
                    Image(systemName: pendingTags.isEmpty ? "checkmark.circle.fill" : "info.circle.fill")
                        .foregroundColor(!pendingTags.isEmpty ? .mint : .red)
                    Text(message).font(.subheadline)
                }
                .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                .padding(.vertical, UIConstants.Padding.capsuleHeight)
                .background(.quaternary)
                .clipShape(.capsule)
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    /// Create grammar point to text association with user feedback
    private func confirmTagging() async {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Error: Please select some text before creating a link."
            return
        }

        let result = await sentenceStore.addPendingTag(grammar: grammarPoint.id, selectedText: selectedText)

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

    /// Dismiss tagging interface and clear selection state
    private func dismissTagger() {
        grammarStore.selectedGrammarPoint = nil
        isShowingTagger = false
    }
}
