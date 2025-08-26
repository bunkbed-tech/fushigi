//
//  GrammarTable.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/20.
//

import SwiftUI

// MARK: Grammar Table

/// Responsive table component for displaying grammar points with adaptive layouts
struct GrammarTable: View {
    /// Centralized grammar data repository with synchronization capabilities
    @EnvironmentObject var grammarStore: GrammarStore

    /// Currently selected grammar point ID
    @Binding var selectedGrammarID: UUID?

    /// Controls inspector visibility
    @Binding var showingInspector: Bool

    /// Grammar points to display in table
    let grammarPoints: [GrammarPointLocal]

    /// Layout mode indicator for responsive design
    let isCompact: Bool

    /// Refresh callback for pull-to-refresh functionality
    let onRefresh: () async -> Void

    // MARK: - Main View

    var body: some View {
        Group {
            if isCompact {
                List(grammarPoints, id: \.id) { point in
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.row) {
                        HStack {
                            Text(point.usage)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.mint)

                            Spacer()

                            Text(point.context)
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
                        grammarStore.selectedGrammarPoint = point
                        showingInspector = true
                    }
                }
            } else {
                Table(grammarPoints, selection: $selectedGrammarID) {
                    TableColumn("場合") { point in
                        Text(point.context)
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
                .onChange(of: selectedGrammarID) { _, new in
                    grammarStore.selectedGrammarPoint = grammarStore.getGrammarPoint(id: new)
                    if new != nil {
                        showingInspector = true
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        #if os(macOS)
            .tableStyle(.inset(alternatesRowBackgrounds: false))
        #endif
            .refreshable {
                await onRefresh()
            }
    }
}

// MARK: - Previews

#Preview {
    @Previewable @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isCompact: Bool { horizontalSizeClass == .compact }

    PreviewHelper.withStore { store, _, _ in
        GrammarTable(
            selectedGrammarID: .constant(nil),
            showingInspector: .constant(true),
            grammarPoints: store.grammarItems,
            isCompact: isCompact,
            onRefresh: {},
        )
    }
}
