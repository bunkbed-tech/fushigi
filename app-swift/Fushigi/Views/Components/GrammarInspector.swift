//
//  GrammarInspector.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/10.
//

import SwiftUI

// MARK: - Grammar Inspector

/// Popup sheet declaration for detailed grammar content dependent on the platform. This is done to have details
/// show separately from the main screen keeping things less cluttered. Not only should it show content, usage,
/// etc, but also example sentences and recent usages in journal entries. Eventually, this could be extended to
/// include a navigation to a page that shows every instance of usage made by the user (aka their sentence bank).
struct GrammarInspector: View {
    // MARK: - Published State

    @EnvironmentObject var studyStore: StudyStore
    @Binding var showDetails: Bool

    /// When dealing with data dependent on both the SRS store and grammar store, use a composite
    /// that favors the SRS store's system state. This is passed by the parent and just used so far to
    /// disable components.
    let systemState: SystemState

    // MARK: - Main View

    var body: some View {
        if let point = studyStore.grammarStore.selectedGrammarPoint {
            PlatformSheet(title: "Grammar Details", onDismiss: { showDetails = false }) {
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
                            if studyStore.srsStore.isInSRS(point.id) {
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

                            if !studyStore.grammarStore.isDefaultGrammar(point) {
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
}
