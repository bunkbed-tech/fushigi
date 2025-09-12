//
//  PracticeView+GrammarSettings.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/09.
//

import SwiftUI

// MARK: - Grammar Settings

/// Settings interface for configuring grammar point selection and filtering. This is currently extremely
/// Japanese specific so if I want to branch out into other languages I will need to make it more generic
/// or introduce some extra flags. The purpose of these settings is to allow the user to influence the
/// "SRS" algorithm to choose a more specific set of daily suggested grammar points. The idea being
/// that if it was truly just SRS based (or even random) then it would be likely you receive completely
/// disparate grammar points (such as Business + Slag in a single entry) that could make it hard to
/// write something cohesive if that's something you want to do.
struct GrammarSettings: View {
    // MARK: - Published State

    /// User preference for politeness level filtering (friends, bosses, customers, etc.)
    @Binding var selectedLevel: Level
    /// User preference for usage context filtering (spoken, written, ancient, business, etc.)
    @Binding var selectedContext: Context
    /// User preference for language variants and regional dialects (slang, onomatope, etc.)
    @Binding var selectedLanguageVariant: LanguageVariants
    /// User preference for grammar sourcing algorithm (random vs. SRS)
    @Binding var selectedSource: SourceMode

    // MARK: - Computed Properties

    /// Footer text explaining the current source mode selection. This is only here in order to try and
    /// improve the UX to help with discoverability and understanding how the app works.
    private var sourceFooterText: String {
        switch selectedSource {
        case .random:
            "Randomly selected grammar points for varied practice"
        case .srs:
            "Algorithmically chosen points based on your learning progress"
        }
    }

    // MARK: - Main View

    var body: some View {
        Form {
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
}
