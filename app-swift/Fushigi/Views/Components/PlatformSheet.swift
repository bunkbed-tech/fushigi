//
//  PlatformSheet.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/07.
//

import SwiftUI

// MARK: - Platform Sheet Helper

/// Cross-platform sheet wrapper using native interaction patterns. This is done to keep MacOS from
/// nesting too many navigation stacks which breaks a lot of toolbar and sheet logic. It also helps me
/// have a separate place to dial in how I want MacOS popups to look which is still a work in progress.
///
/// TODO: Improve the MacOS UI since right now it's only okay.
struct PlatformSheet<Content: View>: View {
    // MARK: - Init

    let title: String
    let onDismiss: () -> Void
    /// All sheet content is passed in as-is from the parent to keep things as generic as possible to styling
    @ViewBuilder let content: Content

    // MARK: - Main View

    var body: some View {
        #if os(macOS)
            VStack(spacing: 0) {
                // Header bar
                HStack {
                    Text(title)
                        .font(.headline)

                    Spacer()

                    Button("Done", action: onDismiss)
                        .buttonStyle(.borderedProminent)
                }
                .padding()

                Divider()

                content
            }
            .frame(minWidth: UIConstants.Sizing.forcedFrameWidth, minHeight: UIConstants.Sizing.forcedFrameHeight)
        #else
            NavigationStack {
                content
                    .toolbar {
                        ToolbarItem {
                            Button("Done", action: onDismiss)
                        }
                    }
            }
            .presentationDetents([.medium, .large], selection: .constant(.large))
        #endif
    }
}
