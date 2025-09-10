//
//  PracticeView+DailyGrammar.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - Daily Grammar

/// Daily grammar section displaying curated grammar points for practice sessions, chosen based on SRS
struct DailyGrammar: View {
    // MARK: - Published State

    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Centralized sentence tag data store
    @EnvironmentObject var sentenceStore: SentenceStore

    /// Controls tagging interface visibility
    @Binding var showTagger: Bool

    /// Controls detailed grammar point inspection interface visibility
    @Binding var showDetails: Bool

    /// User-selected sourcing strategy
    @Binding var selectedSource: SourceMode

    // MARK: - Computed Properties

    /// SRS records based on current sourcing mode
    private var srsRecords: [SRSRecordLocal] {
        studyStore.srsStore.getSRSRecords(for: selectedSource)
    }

    /// Grammar points matching SRS records base on current sourcing mode
    private var grammarPoints: [GrammarPointLocal] {
        studyStore.inSRSGrammarItems.filter { grammarPoint in
            srsRecords.contains(where: { $0.grammar == grammarPoint.id })
        }
    }

    /// All daily items are pulled from SRS records no matter if random or algorithmic
    private var systemState: SystemState {
        studyStore.srsStore.systemState
    }

    // MARK: - Main View

    var body: some View {
        switch systemState {
        case .loading, .criticalError:
            systemState.contentUnavailableView {
                if case .emptyData = systemState {
                    // TODO: reset filters to default?
                }
                await studyStore.refresh()
            }
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
                    if grammarPoints.isEmpty {
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
                        ForEach(grammarPoints, id: \.id) { grammarPoint in
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
                    Text("Tags: \(sentenceStore.pendingSentences.filter { $0.grammar == grammarPoint.id}.count)")
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
        // Hide last Divider for improved visuals
        if grammarPoint.id != grammarPoints.last?.id {
            Divider()
        }
    }
    // MARK: - Helper Methods

    /// Refresh grammar points based on current source mode
    private func refreshGrammarPoints() async {
        studyStore.srsStore.forceDailyRefresh(currentMode: selectedSource)
    }
}
