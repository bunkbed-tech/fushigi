//
//  Extensions.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/20.
//

import SwiftUI

// MARK: - JSON Decoder

// Due to PocketBase using non-standard date and null format, need a special decoder
extension JSONDecoder {
    // JSONDecoder configured for PocketBase which has human readable format
    static var pocketBase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            guard !dateStr.isEmpty else {
                return Date.distantPast // Send old date for null ""
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            guard let date = formatter.date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateStr)")
            }
            return date
        }
        return decoder
    }
}

// MARK: - Platform Dependent Views

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

// MARK: - Notifications

// Add a logout checker to make wiping data stores easier
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
