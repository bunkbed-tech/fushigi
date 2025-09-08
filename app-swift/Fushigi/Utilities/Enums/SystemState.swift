//
//  SystemState.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/23.
//

import SwiftUI

/// The main state that drives UI rendering decisions
enum SystemState: Equatable {
    /// Currently loading locally from SwiftData and fetching remotely from PostgreSQL
    case loading

    /// Standard operation with full data set
    case normal

    /// No data available
    case emptyData

    /// Has data but storage systems are unhealthy
    case degradedOperation(String)

    /// No data and storage systems are unhealthy
    case criticalError(String)

    /// User friendly description of all operating modes
    var description: String {
        switch self {
        case .loading:
            "Currently loading locally from SwiftData and fetching remotely from Pocketbase."
        case .normal:
            "Standard operation with full data set"
        case .emptyData:
            "No data available. Add new items or refresh the app."
        case let .degradedOperation(error):
            "Operating with potentially out of sync data: \(error)"
        case let .criticalError(error):
            "Critical error: \(error)"
        }
    }

    /// Whether this state represents an error condition
    var isErrorState: Bool {
        switch self {
        case .degradedOperation, .criticalError:
            true
        case .loading, .normal, .emptyData:
            false
        }
    }

    /// Whether this state should show a full content unavailable view
    var shouldShowContentUnavailable: Bool {
        switch self {
        case .loading, .criticalError:
            true
        case .normal, .degradedOperation, .emptyData:
            false
        }
    }

    /// Whether this state should disable UI components to prevent race conditions
    var shouldDisableUI: Bool {
        if case .loading = self { return true }
        return false
    }

    // MARK: - View Builders

    /// Returns the appropriate ContentUnavailableView for the current state
    @ViewBuilder
    func contentUnavailableView(action: @escaping () async -> Void) -> some View {
        // .normal and .degradedOperation do not use this view since content is available
        // .emptyData does not use this view since it requires explicit user action to solve (adding new content)
        if case .loading = self {
            ContentUnavailableView {
                VStack(spacing: UIConstants.Spacing.section) {
                    ProgressView()
                        .scaleEffect(2.5)
                        .frame(height: UIConstants.Sizing.icons)
                    Text("Loading")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            } description: {
                Text(description)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if case let .criticalError(error) = self {
            ContentUnavailableView {
                Label("Critical Error", systemImage: "xmark.octagon.fill")
            } description: {
                Text(error)
                    .foregroundColor(.red)
            } actions: {
                Button("Retry") {
                    Task { await action() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
