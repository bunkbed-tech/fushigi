//
//  SystemStateUnitTests.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

@testable import Fushigi
import Testing

// MARK: - System State Unit Tests

struct SystemStateUnitTests {
    @Test func dataAvailabilityDescriptions() {
        #expect(DataAvailability.loading.description == "Loading data...")
        #expect(DataAvailability.available.description == "Data ready")
        #expect(DataAvailability.empty.description == "No data available")
    }

    @Test func systemStateDescriptions() {
        #expect(SystemState.loading.description.contains("loading"))
        #expect(SystemState.normal.description.contains("Standard operation"))
        #expect(SystemState.emptyData.description.contains("No data"))

        let degraded = SystemState.degradedOperation("Test error")
        #expect(degraded.description.contains("Test error"))

        let critical = SystemState.criticalError("Critical test error")
        #expect(critical.description.contains("Critical test error"))
    }

    @Test func systemHealthHasError() {
        #expect(!SystemHealth.healthy.hasError)
        #expect(SystemHealth.swiftDataError.hasError)
        #expect(SystemHealth.pocketbaseError.hasError)
    }
}
