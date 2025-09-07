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
    let title: String
    let onDismiss: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        #if os(macOS)
            // TODO: Simple VStack to avoid sizing issues for now
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
            .frame(minWidth: 320, minHeight: 240)
        #else
            NavigationStack {
                content
                    .navigationTitle(title)
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
