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
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                    Text(selectedGrammarPoint.usage)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(selectedGrammarPoint.meaning)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Divider()

                if !selectedGrammarPoint.notes.isEmpty {
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        Text("Notes")
                            .font(.headline)
                        Text(selectedGrammarPoint.notes)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()
                }

                if !selectedGrammarPoint.forms.isEmpty {
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        Text("Forms")
                            .font(.headline)
                        ForEach(Array(selectedGrammarPoint.forms.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key + ":")
                                    .fontWeight(.medium)
                                Text(selectedGrammarPoint.forms[key] ?? "")
                            }
                        }
                    }

                    Divider()
                }

                if !selectedGrammarPoint.examples.isEmpty {
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        Text("Examples")
                            .font(.headline)
                        ForEach(selectedGrammarPoint.examples, id: \.japanese) { example in
                            VStack(alignment: .leading, spacing: UIConstants.Spacing.tightRow) {
                                Text(example.japanese)
                                    .fontWeight(.medium)
                                Text(example.english)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: UIConstants.Spacing.row))
                        }
                    }

                    Divider()
                }

                coloredTagsText(tags: selectedGrammarPoint.tags + [selectedGrammarPoint.level] + selectedGrammarPoint
                    .context)

                Spacer()

                NavigationLink(value: SentenceBankDestination(grammarPoint: selectedGrammarPoint)) {
                    Text("Sentence Bank")
                }
            }
            .padding()
        }
        .navigationDestination(for: SentenceBankDestination.self) { _ in
            sentenceBank
        }
        .navigationDestination(for: JournalEntryDestination.self) { destination in
            JournalEntryDetailView(journalEntry: destination.entry)
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
                ScrollView {
                    LazyVStack(spacing: UIConstants.Spacing.row) {
                        ForEach(sentences, id: \.self) { sentence in
                            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                                Text(sentence.content)
                                    .fontWeight(.medium)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack {
                                    if let journalEntry = studyStore.journalStore.getJournalEntry(for: sentence) {
                                        NavigationLink(value: JournalEntryDestination(entry: journalEntry)) {
                                            HStack(spacing: UIConstants.Spacing.tightRow) {
                                                Image(systemName: "book.closed")
                                                Text("View Entry")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        }
                                    }

                                    Spacer()

                                    Text(sentence.created.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)

                                    Button("Delete", systemImage: "trash") {
                                        // TODO: Implement sentence delete
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .disabled(true)
                                }
                            }
                            .padding()
                            .background(
                                .quaternary,
                                in: RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius.width),
                            )
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView {
                    Label("No Sentences", systemImage: "text.bubble")
                } description: {
                    Text("Tag sentences in your journal entries to build your sentence bank.")
                }
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

struct SentenceBankDestination: Hashable {
    let grammarPoint: GrammarPointLocal
}

struct JournalEntryDestination: Hashable {
    let entry: JournalEntryLocal
}
