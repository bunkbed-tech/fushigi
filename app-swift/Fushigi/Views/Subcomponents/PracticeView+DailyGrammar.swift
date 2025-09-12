//
//  PracticeView+DailyGrammar.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - Daily Grammar

/// Displays up to 5 curated grammar points for practice sessions, chosen based on SRS records. Users have the
/// ability to actually leverage an "SRS" algorithm or choose completely randomly. Filters are provided to enhance
/// this choice further. By clicking on a grammar item, a detailed grammar sheet will pop up to explain the grammar
/// point further when help is needed. By clickign the + button, a tagger sheet will pop up to aid users in tagging
/// highlighted sentences within their journal entry with the clicked grammar point. Thus, we are able to enable users
/// with a slow creation of a custom sourced sentence bank showing their progress in language learning over time.
struct DailyGrammar: View {
    // MARK: - Published State

    @EnvironmentObject var studyStore: StudyStore
    @EnvironmentObject var sentenceStore: SentenceStore
    @Binding var showTagger: Bool
    @Binding var showDetails: Bool
    /// User preference for grammar sourcing algorithm (random vs. SRS)
    @Binding var selectedSource: SourceMode

    // MARK: - Init

    let currentGrammar: [GrammarPointLocal]

    // MARK: - Computed Properties

    /// Determine the health of the most important store for this view (SRS), whether it's an error state,
    /// loading state, or healthy state
    private var systemState: SystemState {
        studyStore.srsStore.systemState
    }

    // MARK: - Main View

    var body: some View {
        switch systemState {
        case .loading:
            ContentUnavailableView {
                VStack(spacing: UIConstants.Spacing.section) {
                    ProgressView()
                        .scaleEffect(2.5)
                        .frame(height: UIConstants.Sizing.icons)
                }
            } description: {
                Text("Currently loading daily study list...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .criticalError:
            systemState.contentUnavailableView { await studyStore.refresh() }
        case .normal, .degradedOperation, .emptyData:
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                HStack {
                    Text("Targeted Grammar")
                        .font(.headline)

                    Spacer()

                    Text(selectedSource.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                        .padding(.vertical, UIConstants.Padding.capsuleHeight)
                        .background(.quaternary)
                        .clipShape(.capsule)
                }

                Divider()

                VStack {
                    if currentGrammar.isEmpty {
                        ContentUnavailableView {
                            Label("No SRS Records", systemImage: "tray")
                        } description: {
                            Text("""
                            Try adding new grammar points, changing the filter,
                            or bulk generating SRS items on the Reference Page.
                            """)
                            .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(currentGrammar, id: \.id) { grammarPoint in
                            dailyGrammarRow(grammarPoint: grammarPoint)
                        }
                    }
                }
            }
            .overlay(alignment: .centerFirstTextBaseline) {
                if case .degradedOperation = systemState {
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
                }
            }
        }
    }

    // MARK: - Sub Views

    /// Each row of the DailyGrammar object should feature the usage of the grammar point, a counter
    /// showing the current number of tags (to help nudge users towards discoverability of the tagging
    /// feature) as well as a + button to actually add the tag. This was split with the main code in order
    /// to help with compilation in XCode.
    @ViewBuilder
    private func dailyGrammarRow(grammarPoint: GrammarPointLocal) -> some View {
        HStack {
            Button {
                studyStore.grammarStore.selectedGrammarPoint = grammarPoint
                showDetails = true
            } label: {
                HStack {
                    Text(grammarPoint.usage)
                        .foregroundStyle(.foreground)
                    Spacer()
                    Text("Tags: \(sentenceStore.pendingSentences.count(where: { $0.grammar == grammarPoint.id }))")
                        .clipShape(.capsule)
                        .font(.caption2)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help("View grammar usage details to rejog your memory.")

            Button {
                studyStore.grammarStore.selectedGrammarPoint = grammarPoint
                showTagger = true
            } label: {
                Label("Add Tag", systemImage: "plus.circle.fill")
                    .labelStyle(.iconOnly)
            }
            .help("Select a sentence and click this to add/view tags and build your sentence bank over time.")
        }
        // Hide last Divider for improved UX visuals
        if grammarPoint.id != currentGrammar.last?.id {
            Divider()
        }
    }
}
