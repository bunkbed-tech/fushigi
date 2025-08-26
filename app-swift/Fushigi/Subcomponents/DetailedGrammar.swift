//
//  DetailedGrammar.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/08.
//

import SwiftUI

// MARK: - DetailedGrammar

/// Detailed view displaying comprehensive grammar point information
struct DetailedGrammar: View {
    /// Controls view presentation state
    @Binding var isPresented: Bool

    /// Grammar point to display
    let grammarPoint: GrammarPointLocal

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.section) {
            HStack(spacing: UIConstants.Spacing.default) {
                Button("Dismiss") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Edit") {
                    print("Editing grammar point. TODO: implement.")
                }
                .buttonStyle(.borderedProminent)
            }
            VStack(alignment: .leading) {
                Text("Usage: \(grammarPoint.usage)")
                Text("Meaning: \(grammarPoint.meaning)")
                Divider()
                coloredTagsText(tags: grammarPoint.tags)
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}

// MARK: - Previews

#Preview {
    PreviewHelper.withStore { store, _, _ in
        DetailedGrammar(
            isPresented: .constant(true),
            grammarPoint: store.grammarItems.first!,
        )
    }
}
