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

    /// As special version of emptiness where there are specifically no SRS records
    case emptySRS

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
        case .emptySRS:
            "No SRS data available. Under 'Reference', select a grammar item and add to SRS."
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
        case .loading, .normal, .emptyData, .emptySRS:
            false
        }
    }

    /// Whether this state should show a full content unavailable view
    var shouldShowContentUnavailable: Bool {
        switch self {
        case .loading, .emptyData, .emptySRS, .criticalError:
            true
        case .normal, .degradedOperation:
            false
        }
    }

    // MARK: - View Builders

    /// Returns the appropriate ContentUnavailableView for the current state
    @ViewBuilder
    func contentUnavailableView(onRefresh: @escaping () async -> Void) -> some View {
        Group {
            switch self {
            case .normal, .degradedOperation:
                // Normal state doesn't need an error view
                EmptyView()

            case .loading:
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

            case .emptyData:
                ContentUnavailableView {
                    Label("No Data", systemImage: "tray")
                } description: {
                    Text(description)
                        .foregroundColor(.secondary)
                } actions: {
                    Button("Refresh") {
                        Task { await onRefresh() }
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .emptySRS:
                ContentUnavailableView {
                    Label("No SRS Records", systemImage: "graduationcap")
                } description: {
                    Text(description)
                        .foregroundColor(.secondary)
                }

            case let .criticalError(error):
                ContentUnavailableView {
                    Label("Critical Error", systemImage: "xmark.octagon.fill")
                } description: {
                    Text(error)
                        .foregroundColor(.red)
                } actions: {
                    Button("Retry") {
                        Task { await onRefresh() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
