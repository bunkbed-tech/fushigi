//
//  Extensions.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/20.
//

import SwiftUI

extension JSONDecoder {
    // JSONDecoder configured for PocketBase which has human readable format
    static var pocketBase: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}

extension View {
    /// Apply tab bar minimize behavior if available on iOS 26+
    @ViewBuilder
    func tabBarMinimizeOnScrollIfAvailable() -> some View {
        #if os(iOS)
            // The following check only works on xcode-beta right now
            if #available(iOS 26.0, *) {
                self.tabBarMinimizeBehavior(.onScrollDown)
            } else {
                self
            }
        #else
            self
        #endif
    }
}

extension View {
    /// Conditionally apply searchable modifier for iPad since views can either be macOS-like or iPhone-like
    @ViewBuilder
    func searchableIf(_ condition: Bool, text: Binding<String>, prompt: String = "Search") -> some View {
        if condition {
            searchable(text: text, prompt: prompt)
        } else {
            self
        }
    }
}

extension View {
    /// Add fake datastore for Preview mode
    func withPreviewStores(
        dataAvailability: DataAvailability = .available,
        systemHealth: SystemHealth = .healthy,
        systemState: SystemState = .normal,
        noSRS: Bool = false,
    ) -> some View {
        PreviewHelper.withStore(
            dataAvailability: dataAvailability,
            systemHealth: systemHealth,
            systemState: systemState,
            noSRS: noSRS,
        ) { _, _, _ in
            self
        }
    }

    /// Wrap view in NavigationStack for preview components + add styling
    func withPreviewNavigation() -> some View {
        NavigationStack {
            self.background {
                LinearGradient(
                    colors: [.mint.opacity(0.2), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
    }
}

// Add a logout checker to make wiping data stores easier
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
