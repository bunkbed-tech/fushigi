//
//  DailyGrammar.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - Daily Grammar

/// Daily grammar section displaying curated grammar points for practice sessions
struct DailyGrammar: View {
    /// Centralized grammar data store
    @EnvironmentObject var grammarStore: GrammarStore

    /// Controls tagging interface visibility
    @Binding var showTagger: Bool

    /// User-selected grammar sourcing strategy
    @Binding var selectedSource: SourceMode

    /// Grammar points based on current sourcing mode
    private var grammarPoints: [GrammarPointLocal] {
        grammarStore.getGrammarPoints(for: selectedSource)
    }

    // MARK: - Main View

    var body: some View {
        switch grammarStore.systemState {
        case .loading, .emptyData, .criticalError:
            grammarStore.systemState.contentUnavailableView {
                if case .emptyData = grammarStore.systemState {
                    // TODO: reset filters to default?
                }
                await grammarStore.refresh()
            }
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
                                grammarStore.selectedGrammarPoint = grammarPoint
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
        }
    }

    // MARK: - Helper Methods

    /// Refresh grammar points based on current source mode
    private func refreshGrammarPoints() async {
        grammarStore.forceDailyRefresh(currentMode: selectedSource)
    }
}

// MARK: - Previews

#Preview("Random - Normal") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.random),
    )
    .withPreviewNavigation()
    .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}

#Preview("SRS - Normal") {
    DailyGrammar(
        showTagger: .constant(false),
        selectedSource: .constant(SourceMode.srs),
    )
    .withPreviewNavigation()
    .withPreviewStores(dataAvailability: .available, systemHealth: .healthy)
}
