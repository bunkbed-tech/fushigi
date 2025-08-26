//
//  Extensions.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/20.
//

import SwiftUI

// MARK: - Extensions

extension JSONDecoder {
    /// JSONDecoder configured for ISO8601 dates with fractional seconds from timestamptz
    static var iso8601withFractionalSeconds: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            guard let date = formatter.date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date string: \(dateStr)",
                )
            }
            return date
        }
        return decoder
    }
}

extension View {
    /// Apply tab bar minimize behavior if available on iOS 26+
    @ViewBuilder
    func tabBarMinimizeOnScrollIfAvailable() -> some View {
        #if os(iOS)
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
    func withPreviewStores(dataAvailability: DataAvailability = .available,
                           systemHealth: SystemHealth = .healthy) -> some View
    {
        PreviewHelper.withStore(dataAvailability: dataAvailability, systemHealth: systemHealth) { _, _, _ in
            self
        }
    }

    /// Wrap view in NavigationStack for preview components
    func withPreviewNavigation() -> some View {
        NavigationStack {
            self
        }
    }
}
