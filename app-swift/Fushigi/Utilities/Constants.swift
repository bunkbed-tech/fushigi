//
//  Constants.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/19.
//

import SwiftUI

// MARK: - UI Constants

/// Common UI spacing and sizing constants
enum UIConstants {
    enum Spacing {
        /// Content spacing. Value: 20.0
        static let content: CGFloat = 20

        /// Section spacing. Value: 16.0
        static let section: CGFloat = 16

        /// Row spacing. Value: 8.0
        static let row: CGFloat = 8

        /// Tight row spacing. Value: 4.0
        static let tightRow: CGFloat = 4

        /// Default spacing. Value: 20.0
        static let `default`: CGFloat = 20
    }

    enum Sizing {
        /// Content minimum height sizing. Value: 150.0
        static let contentMinHeight: CGFloat = 150

        /// Default padding sizing. Value: 10.0
        static let defaultPadding: CGFloat = 10

        /// Font sizing. Value: 18.0
        static let fontSize: CGFloat = 18

        /// Icon sizing. Value: 60.0
        static let icons: CGFloat = 60

        /// Big icon sizing. Value: 120.0
        static let bigIcons: CGFloat = 120

        /// Corner radius sizing. Value: Width = 8, Height = 8
        static let cornerRadius: CGSize = .init(width: 8, height: 8)
    }

    enum Border {
        /// Border width. Value: 1.0
        static let width: CGFloat = 1

        /// Focused border width. Value: 2.0
        static let focusedWidth: CGFloat = 2
    }

    enum Padding {
        /// Capsule padding width. Value: 8.0
        static let capsuleWidth: CGFloat = 8

        /// Capsule padding height. Value: 2.0
        static let capsuleHeight: CGFloat = 2

        /// Large indent padding. Value: 32.0
        static let largeIndent: CGFloat = 32
    }
}
