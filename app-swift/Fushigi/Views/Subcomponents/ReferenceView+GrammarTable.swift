//
//  ReferenceView+GrammarTable.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/20.
//

import SwiftUI

// MARK: - Grammar Table

/// Responsive table component for displaying grammar points with adaptive layouts. The two views are either
/// a fully functional table on MacOS and iPad, or a simple single column list on iOS. Rather than being platform
/// dependent, it is "compact" dependent. Pull to refresh is currently implemented, although the UX of it is a bit
/// janky with it being too easy to cancel the refresh and result in an out of sync error message.
struct GrammarTable: View {
    // MARK: - Published State

    @Binding var selectedGrammarPoint: GrammarPointLocal?
    @State private var selectedGrammarID: String?

    // MARK: - Init

    let grammarPoints: [GrammarPointLocal]
    /// Flag to get iPadOS to utilize iOS features vs MacOS features based on window size
    let isCompact: Bool
    let onRefresh: () async -> Void

    // MARK: - Main View

    var body: some View {
        Group {
            if isCompact {
                grammarAsList
            } else {
                grammarAsTable
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .refreshable {
            await onRefresh()
        }
    }

    @ViewBuilder
    private var grammarAsList: some View {
        List(grammarPoints, id: \.id) { point in
            VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                HStack {
                    Text(point.usage)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.mint)

                    Spacer()

                    Text(point.notes)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.purple)
                }

                Text(point.meaning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !point.tags.isEmpty {
                    coloredTagsText(tags: point.tags)
                }
            }
            .padding(UIConstants.Sizing.defaultPadding)
            .contentShape(.rect)
            .onTapGesture {
                selectedGrammarPoint = point
            }
        }
    }

    @ViewBuilder
    private var grammarAsTable: some View {
        Table(grammarPoints, selection: $selectedGrammarID) {
            TableColumn("場合") { point in
                Text(point.notes)
            }
            TableColumn("使い方") { point in
                VStack(alignment: .leading) {
                    Text(point.usage)
                    Text(point.meaning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(nil)
            }
            TableColumn("タッグ") { point in
                coloredTagsText(tags: point.tags)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: selectedGrammarID) { _, newID in
            if let newID,
               let selectedPoint = grammarPoints.first(where: { $0.id == newID })
            {
                selectedGrammarPoint = selectedPoint
            }
        }
        #if os(macOS)
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        #endif
    }
}
