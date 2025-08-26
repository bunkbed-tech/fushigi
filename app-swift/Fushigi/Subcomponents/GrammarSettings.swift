//
//  GrammarSettings.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/09.
//

import SwiftUI

// MARK: - Grammar Settings

/// Settings interface for configuring grammar point selection and filtering
struct GrammarSettings: View {
    /// Politeness level filter selection
    @Binding var selectedLevel: Level

    /// Usage context filter selection
    @Binding var selectedContext: Context

    /// Language variant filter selection
    @Binding var selectedLanguageVariant: LanguageVariants

    /// Grammar sourcing algorithm selection
    @Binding var selectedSource: SourceMode

    // MARK: - Main View

    var body: some View {
        Form {
            // Primary sourcing method configuration
            Section {
                Picker("Grammar Source", selection: $selectedSource) {
                    ForEach(SourceMode.allCases) { source in
                        Label(source.displayName, systemImage: source.icon)
                            .tag(source)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Source Method")
            } footer: {
                Text(sourceFooterText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Content filtering options
            Section("Content Filters") {
                Picker("Usage Context", selection: $selectedContext) {
                    ForEach(Context.allCases) { context in
                        Text(context.displayName).tag(context)
                    }
                }

                Picker("Politeness Level", selection: $selectedLevel) {
                    ForEach(Level.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Picker("Language Variants", selection: $selectedLanguageVariant) {
                    ForEach(LanguageVariants.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helper Methods

    /// Footer text explaining the current source mode selection
    private var sourceFooterText: String {
        switch selectedSource {
        case .random:
            "Randomly selected grammar points for varied practice"
        case .srs:
            "Algorithmically chosen points based on your learning progress"
        }
    }
}

// MARK: - Previews

#Preview("Random") {
    GrammarSettings(
        selectedLevel: .constant(.all),
        selectedContext: .constant(.all),
        selectedLanguageVariant: .constant(.none),
        selectedSource: .constant(.random),
    )
    .withPreviewNavigation()
    .navigationTitle("Practice Settings")
}

#Preview("SRS") {
    GrammarSettings(
        selectedLevel: .constant(.all),
        selectedContext: .constant(.all),
        selectedLanguageVariant: .constant(.none),
        selectedSource: .constant(.srs),
    )
    .withPreviewNavigation()
    .navigationTitle("Practice Settings")
}
