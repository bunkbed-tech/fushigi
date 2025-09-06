//
//  DailyGrammar.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

/// Daily grammar section displaying curated grammar points for practice sessions, chosen based on SRS
struct DailyGrammar: View {
    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Centralized on-device storage for user's grammar points (used for application state)
    @EnvironmentObject var grammarStore: GrammarStore

    /// Centralized on-device storage for user's srs records
    @EnvironmentObject var srsStore: SRSStore

    /// Controls tagging interface visibility
    @Binding var showTagger: Bool

    /// User-selected sourcing strategy
    @Binding var selectedSource: SourceMode

    /// SRS records based on current sourcing mode
    private var srsRecords: [SRSRecordLocal] {
        srsStore.getSRSRecords(for: selectedSource)
    }

    /// Grammar points matching SRS records base on current sourcing mode
    private var grammarPoints: [GrammarPointLocal] {
        studyStore.inSRSGrammarItems.filter { grammarPoint in
            srsRecords.contains(where: { $0.grammar == grammarPoint.id })
        }
    }

    /// Combine states from both stores and let grammar state win, reimplementing the computation in SyncableStore
    private var systemState: SystemState {
        studyStore.systemState
    }

    // MARK: - Main View

    var body: some View {
        switch systemState {
        case .loading, .emptyData, .criticalError:
            systemState.contentUnavailableView {
                if case .emptyData = systemState {
                    // TODO: reset filters to default?
                }
                await studyStore.refresh()
            }
        case .emptySRS:
            systemState.contentUnavailableView {}
        case .normal, .degradedOperation:
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
                    ForEach(grammarPoints, id: \.id) { grammarPoint in
                        TaggableGrammarRow(
                            grammarPoint: grammarPoint,
                            onTagSelected: {
                                studyStore.grammarStore.selectedGrammarPoint = grammarPoint
                                showTagger = true
                            },
                        )

                        // Hide last Divider for improved visuals
                        if grammarPoint.id != grammarPoints.last?.id {
                            Divider()
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

    // MARK: - Helper Methods

    /// Refresh grammar points based on current source mode
    private func refreshGrammarPoints() async {
        srsStore.forceDailyRefresh(currentMode: selectedSource)
    }
}

// MARK: - Previews

#Preview("Random - Normal") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.random),
    )
    .withPreviewNavigation()
    .withPreviewStores()
}

#Preview("SRS - Normal") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.srs),
    )
    .withPreviewNavigation()
    .withPreviewStores()
}

#Preview("Random - Pocketbase error") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.random),
    )
    .withPreviewNavigation()
    .withPreviewStores(systemHealth: .pocketbaseError)
}

#Preview("Empty SRS") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.random),
    )
    .withPreviewNavigation()
    .withPreviewStores(systemState: .emptySRS)
}
