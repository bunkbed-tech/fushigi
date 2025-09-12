//
//  UIConstants.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - UIConstants

/// Common UI spacing and sizing constants in order to easily iterate through sizes across the entire app when improving
/// the
/// UX. This also keeps me from defining magic numbers everywhere and forgetting the follows I used for other spacings.
/// Essentially, the goal is uniformity with this.
enum UIConstants {
    // MARK: - Spacing

    enum Spacing {
        /// Value: 20.0
        static let content: CGFloat = 20
        /// Value: 16.0
        static let section: CGFloat = 16
        /// Value: 8.0
        static let row: CGFloat = 8
        /// Value: 4.0
        static let tightRow: CGFloat = 4
        /// Value: 20.0
        static let `default`: CGFloat = 20
    }

    // MARK: - Sizing

    enum Sizing {
        /// Value: 150.0
        static let contentMinHeight: CGFloat = 150
        /// Value: 10.0
        static let defaultPadding: CGFloat = 10
        /// Value: 18.0
        static let fontSize: CGFloat = 18
        /// Value: 60.0
        static let icons: CGFloat = 60
        /// Value: 120.0
        static let bigIcons: CGFloat = 120
        /// Value: Width = 8, Height = 8
        static let cornerRadius: CGSize = .init(width: 8, height: 8)
        /// Value: 450
        static let forcedFrameWidth: CGFloat = 450
        /// Value: 300
        static let forcedFrameHeight: CGFloat = 300
    }

    // MARK: - Border

    enum Border {
        /// Value: 1.0
        static let width: CGFloat = 1
        /// Value: 2.0
        static let focusedWidth: CGFloat = 2
    }

    // MARK: - Padding

    enum Padding {
        /// Value: 8.0
        static let capsuleWidth: CGFloat = 8
        /// Value: 2.0
        static let capsuleHeight: CGFloat = 2
        /// Value: 32.0
        static let largeIndent: CGFloat = 32
    }
}
