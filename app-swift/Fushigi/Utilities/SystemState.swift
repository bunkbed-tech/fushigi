//
//  SystemState.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/23.
//

import SwiftUI

// MARK: - System State

/// The main state that drives UI rendering decisions. This is my attempt to simplify things across views but it has
/// resulted in a lot of complexity and visual bugs at times so it is worthwhile to vigourously test in the future.
///
/// TODO: Add rigorous tests across the enum to make sure not only UX works, but intelligent errors are displayed
enum SystemState: Equatable {
    case loading
    case normal
    case emptyData
    /// Data exists but storage systems are unhealthy (syncing could not be performed at this moment)
    case degradedOperation(String)
    /// No data and storage systems are unhealthy (syncing could not be performed at this moment)
    case criticalError(String)

    var description: String {
        switch self {
        case .loading:
            "Currently loading locally from SwiftData and fetching remotely from PocketBase."
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

    /// Do not consider empty data as an error state although it could occur from an actual error. The idea here is that
    /// only true errors
    /// coming from SwiftData or PocketBase should raise the error state modes of degraded operation and critical error.
    var isErrorState: Bool {
        switch self {
        case .degradedOperation, .criticalError:
            true
        case .loading, .normal, .emptyData:
            false
        }
    }

    /// Only the loading and critical error states correspond to moments when the data is either empty or could be empty
    /// due to a forced
    /// data wipe during resync for example.
    var shouldShowContentUnavailable: Bool {
        switch self {
        case .loading, .criticalError:
            true
        case .normal, .degradedOperation, .emptyData:
            false
        }
    }

    /// The loading state should always disable UI components so users cannot accidently mess up async processes by
    /// interacting with buttons and modals when operations are running.
    var shouldDisableUI: Bool {
        if case .loading = self { return true }
        return false
    }

    // MARK: - View Builders

    /// Returns the appropriate ContentUnavailableView for the current state. At many times I have had to reimplement
    /// this without using this helper
    /// per view so it might be worth removing in the future or making more intelligent.
    ///
    /// TODO: Look into usage to simplify or remove entirely.
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
