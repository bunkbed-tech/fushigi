//
//  SubNavigatorView.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/07.
//

import SwiftUI

// MARK: - Sub Navigator View

/// Sub navigation wrapper using native interaction patterns. This is done to allow a separate
/// navigation framework outside of the main app. For example, for sheets and detail views.
struct SubNavigatorView<Content: View>: View {
    // MARK: - Init

    let title: String
    let onDismiss: () -> Void

    @ViewBuilder let content: Content

    // MARK: - Main View

    var body: some View {
        #if os(macOS)
            NavigationStack {
                content
            }
        #else
            NavigationStack {
                content
                    .scrollContentBackground(.hidden)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large], selection: .constant(.medium))
        #endif
    }
}
