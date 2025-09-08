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

    /// All daily items are pulled from SRS records no matter if random or algorithmic
    private var systemState: SystemState {
        srsStore.systemState
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
                            Button {
                                studyStore.grammarStore.selectedGrammarPoint = grammarPoint
                                showTagger = true
                            } label: {
                                HStack {
                                    Text(grammarPoint.usage)
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.mint)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .help("Link this grammar point to selected text")

                            // Hide last Divider for improved visuals
                            if grammarPoint.id != grammarPoints.last?.id {
                                Divider()
                            }
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
