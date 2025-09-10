//
//  GrammarInspector.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/10.
//

import SwiftUI

// MARK: - Grammar Inspector

/// Popup sheet declaration for detailed grammar content, platform dependent
struct GrammarInspector: View {
    // MARK: - Published State

    /// Centralized on-device storage for user's grammar points + srs records and application state
    @EnvironmentObject var studyStore: StudyStore

    /// Controls inspector visibility
    @Binding var showDetails: Bool

    /// Computed system state based on current filter
    let systemState: SystemState

    // MARK: - Main View
    var body: some View {
        if let point = studyStore.grammarStore.selectedGrammarPoint {
            PlatformSheet(title: "Grammar Details", onDismiss: { showDetails = false }) {
                grammarContent(
                    point: point,
                    isInSRS: studyStore.srsStore.isInSRS(point.id),
                    isDefault: studyStore.grammarStore.isDefaultGrammar(point),
                )
            }
            #if os(macOS)
            .frame(minWidth: UIConstants.Sizing.forcedFrameWidth, minHeight: UIConstants.Sizing.forcedFrameHeight)
            #else
            .presentationDetents([.medium, .large], selection: .constant(.medium))
            #endif
        } else {
            ContentUnavailableView {
                Label("Error", systemImage: "xmark.circle")
            } description: {
                Text("Selected grammar is null. Please report this bug.")
            } actions: {
                Button("Dismiss") {
                    showDetails = false
                }
                .buttonStyle(.borderedProminent)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sub Views
    /// Detailed grammar content showing up on popup sheet
    @ViewBuilder
    private func grammarContent(point: GrammarPointLocal, isInSRS: Bool, isDefault: Bool) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            Text("Usage: \(point.usage)")
            Text("Meaning: \(point.meaning)")
            Divider()
            coloredTagsText(tags: point.tags)
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    if isInSRS {
                        Button("Remove from SRS", systemImage: "rectangle.on.rectangle.slash") {
                            print("TODO: Implement remove from SRS")
                        }
                        .disabled(true)
                    } else {
                        Button("Add to SRS", systemImage: "plus.rectangle.on.rectangle") {
                            Task {
                                await studyStore.srsStore.addToSRS(point.id)
                                showDetails = false
                            }
                        }
                    }

                    if !isDefault {
                        Button("Edit", systemImage: "square.and.arrow.up.fill") {
                            print("TODO: Implement editing user grammar point...")
                        }
                        .disabled(true)

                        Button("Delete", systemImage: "trash.slash") {
                            print("TODO: Implement removing user grammar point...")
                        }
                        .disabled(true)
                    }
                }
                .labelStyle(.iconOnly)
                .disabled(systemState.shouldDisableUI)
            }
        }
    }
}
