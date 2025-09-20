//
//  GrammarInspector.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/10.
//

import SwiftUI

// MARK: - Grammar Inspector

/// Basic view declaration for detailed grammar content dependent on the platform. This is done to have details
/// show separately from the main screen keeping things less cluttered. Not only should it show content, usage,
/// etc, but also example sentences and recent usages in journal entries. Eventually, this could be extended to
/// include a navigation to a page that shows every instance of usage made by the user (aka their sentence bank).
struct GrammarInspector: View {
    // MARK: - Published State

    @EnvironmentObject var studyStore: StudyStore

    // MARK: - Init

    let selectedGrammarPoint: GrammarPointLocal

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            Text("Usage: \(selectedGrammarPoint.usage)")
            Text("Meaning: \(selectedGrammarPoint.meaning)")
            Divider()
            coloredTagsText(tags: selectedGrammarPoint.tags)
            Spacer()
            NavigationLink("Sentence Bank", destination: sentenceBank)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Options", systemImage: "square.and.pencil") {
                    if studyStore.srsStore.isInSRS(selectedGrammarPoint.id) {
                        Button("Ignore in SRS", systemImage: "rectangle.on.rectangle.slash") {
                            print("TODO: Implement remove from SRS")
                        }
                        .labelStyle(.titleAndIcon)
                        .disabled(true)
                    } else {
                        Button("Track in SRS", systemImage: "plus.rectangle.on.rectangle") {
                            Task {
                                await studyStore.srsStore.addToSRS(selectedGrammarPoint.id)
                            }
                        }
                        .labelStyle(.titleAndIcon)
                    }

                    Button("Edit", systemImage: "square.and.arrow.up.fill") {
                        print("TODO: Implement editing user grammar point...")
                    }
                    .labelStyle(.titleAndIcon)
                    .disabled(true)

                    Button("Delete", systemImage: "trash.slash") {
                        print("TODO: Implement removing user grammar point...")
                    }
                    .labelStyle(.titleAndIcon)
                    .disabled(true)
                }
                .labelStyle(.iconOnly)
                .disabled(studyStore.srsStore.systemState.shouldDisableUI)
            }
        }
        .navigationTitle("Grammar Details")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .containerBackground(.clear, for: .navigation)
        #else
            .background {
                LinearGradient(
                    colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
            }
        #endif
    }

    /// Display a sentence bank for all instances of the currently selected grammar
    /// point. This way a user can easily go back in time and see examples of
    /// previous usages or how they have improved over time. It can also help them
    /// not create a sentence tag with the same exact content that they already have
    /// done before to keep things fresh.
    @ViewBuilder
    private var sentenceBank: some View {
        let sentences = studyStore.getSentencesForGrammar(selectedGrammarPoint.id)
        Group {
            if !sentences.isEmpty {
                List(sentences, id: \.self) { sentence in
                    HStack {
                        Text(sentence.content)
                        Spacer()
                        Button("Delete") {
                            // TODO: Implement sentence delete
                        }
                        .disabled(true)
                    }
                }
            } else {
                Text("No sentences tagged with this grammar point.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Sentence Bank")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .containerBackground(.clear, for: .navigation) // needed to get LiquidGlass
        #else
            .background {
                LinearGradient(
                    colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
            }
        #endif
    }
}
