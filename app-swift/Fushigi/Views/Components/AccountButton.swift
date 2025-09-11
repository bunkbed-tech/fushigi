//
//  AccountButton.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/09.
//

import SwiftUI

// MARK: - Account Button

/// Account button that opens settings (macOS) or sheet (iOS)
struct AccountButton: View {
    @Binding var showProfile: Bool
    #if os(macOS)
        @Environment(\.openSettings) private var openSettings
    #endif

    var body: some View {
        Button("Account", systemImage: "person.circle") {
            #if os(macOS)
                openSettings()
            #else
                showProfile = true
            #endif
        }
    }
}
