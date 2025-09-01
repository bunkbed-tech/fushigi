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
            "Currently loading locally from SwiftData and fetching remotely from PostgreSQL"
        case .normal:
            "Standard operation with full data set"
        case .emptyData:
            "No data available"
        case let .degradedOperation(error):
            "Operating with potentially out of sync data: \(error)"
        case let .criticalError(error):
            "Critical error: \(error)"
        }
    }

    // MARK: - View Builders

    /// Returns the appropriate ContentUnavailableView for the current state
    @ViewBuilder
    func contentUnavailableView(fixAction: @escaping () async -> Void) -> some View {
        Group {
            switch self {
            case .normal:
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
                } actions: {
                    Button("Quit") {
                        Task { await fixAction() }
                    }
                    .buttonStyle(.bordered)
                }

            case .emptyData:
                ContentUnavailableView {
                    Label("No Data", systemImage: "tray")
                } description: {
                    Text(description)
                        .foregroundColor(.secondary)
                } actions: {
                    Button("Refresh") {
                        Task { await fixAction() }
                    }
                    .buttonStyle(.bordered)
                }

            case let .degradedOperation(error):
                ContentUnavailableView {
                    Label("Limited Functionality", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error)
                        .foregroundColor(.orange)
                } actions: {
                    Button("Retry") {
                        Task { await fixAction() }
                    }
                    .buttonStyle(.bordered)
                }

            case let .criticalError(error):
                ContentUnavailableView {
                    Label("Critical Error", systemImage: "xmark.octagon.fill")
                } description: {
                    Text(error)
                        .foregroundColor(.red)
                } actions: {
                    Button("Retry") {
                        Task { await fixAction() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Returns the appropriate potential error banner for the current state
    @ViewBuilder
    func errorBannerView(fixAction: @escaping () async -> Void) -> some View {
        Group {
            switch self {
            case .normal, .loading, .emptyData:
                // Not error states so don't need an error banner
                EmptyView()

            case let .degradedOperation(error), let .criticalError(error):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Grammar points may not be current: \(error)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Retry") {
                        Task { await fixAction() }
                    }
                    .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                    .padding(.vertical, UIConstants.Padding.capsuleHeight)
                    .clipShape(.capsule)
                }
                .padding(.horizontal, UIConstants.Padding.capsuleWidth)
                .padding(.vertical, UIConstants.Padding.capsuleHeight)
                .background(Color.orange.opacity(0.1))
                .clipShape(.capsule)
                .listRowBackground(Color.clear)
                .listRowSeparator(Visibility.hidden, edges: .all)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
