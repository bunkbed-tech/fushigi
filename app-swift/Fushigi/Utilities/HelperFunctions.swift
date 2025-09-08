//
//  HelperFunctions.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import SwiftData
import SwiftUI
import TipKit
import WrappingHStack

/// Create colored text from array of tags
@ViewBuilder
func coloredTagsText(tags: [String]) -> some View {
    WrappingHStack(alignment: .leading) {
        ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
            Text(tag)
                .font(.caption)
                .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                .padding(.vertical, UIConstants.Padding.capsuleHeight)
                .background(index.isMultiple(of: 2) ? .purple.opacity(0.3) : .mint.opacity(0.3))
                .clipShape(.capsule)
        }
    }
}

/// Wipe all data from persistent storage for debug mode
@MainActor
func wipeSwiftData(container: ModelContainer) {
    let context = container.mainContext

    do {
        try Tips.resetDatastore()
        try context.delete(model: GrammarPointLocal.self)
        try context.delete(model: JournalEntryLocal.self)
        try context.delete(model: SentenceLocal.self)
        try context.delete(model: SRSRecordLocal.self)

        try context.save()
        print("LOG: SwiftData store wiped successfully")
    } catch {
        print("ERROR: Failed to wipe SwiftData: \(error)")
    }
}
