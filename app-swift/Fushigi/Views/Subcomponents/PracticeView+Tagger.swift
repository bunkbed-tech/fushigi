//
//  PracticeView+Tagger.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

/// Interface for creating links between selected text and grammar concepts. The current implementation is
/// simplified to show the desired tag text, the list of tags made for this grammar point in the current session
/// (in case users are purposefully writing sentences with it more than once per session and want to log that)
/// and an alert when things are successful. Note that these tags are only temporary and will not be formally
/// submitted to the databaser until the journal entry parent is actually submitted. Thus, users can freely
/// delete the tags on this view without running into sync issues. This helps with the concept of drafts or
/// changing ones mind before they want to set that an item was studied in stone.
struct Tagger: View {
    // MARK: - Published State

    @EnvironmentObject var grammarStore: GrammarStore
    @EnvironmentObject var sentenceStore: SentenceStore
    @Binding var statusMessage: String?
    @Binding var showTagger: Bool

    // MARK: - Computed Properties

    /// Track successful tag creations for user feedback, allow for deletes and showing a counter
    /// on the main screen with the goal of improving user discoverability of this feature
    private var pendingTags: [SentenceCreate] {
        sentenceStore.pendingSentences.filter { $0.grammar == grammarPoint.id }
    }

    // MARK: - Init

    let grammarPoint: GrammarPointLocal
    let selectedText: String

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.default) {
            HStack(spacing: UIConstants.Spacing.default) {
                #if os(macOS)
                    Button("Dismiss") {
                        grammarStore.selectedGrammarPoint = nil
                        showTagger = false
                    }
                    .buttonStyle(.bordered)
                #endif
                Spacer()
                Button("Confirm") { Task { await confirmTagging() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                Label("Selected Text", systemImage: "text.quote")
                    .font(.headline)

                Text(selectedText.isEmpty ? "No text selected" : selectedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UIConstants.Sizing.defaultPadding)
                    .overlay(
                        // TODO: this capsule does not look good with lots of text
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

    /// Create grammar point to journal association with user feedback that the item was successfully
    /// appended to the list. This doesn't actually add it to the database though and is just a UX
    /// feature to feel like something just happened.
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
}
