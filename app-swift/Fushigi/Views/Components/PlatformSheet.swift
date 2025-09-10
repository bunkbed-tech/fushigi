//
//  PlatformSheet.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/07.
//

import SwiftUI

// MARK: - Platform Sheet Helper

/// Cross-platform sheet wrapper using native interaction patterns
struct PlatformSheet<Content: View>: View {
    // MARK: - Init

    /// Title to display on the popup sheet
    let title: String

    /// Action to perform when clicking popup sheet dismiss button
    let onDismiss: () -> Void

    /// All sheet content is passed in as-is
    @ViewBuilder let content: Content

    // MARK: - Main View

    var body: some View {
        #if os(macOS)
            // TODO: Would prefer something better looking on MacOS but this works for now
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
