//
//  FushigiUITests.swift
//  FushigiUITests
//
//  Created by Tahoe Schrader on 2025/08/01.
//

import XCTest

final class FushigiUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for
        // your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the
        // class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testLoginFlowWithTestCredentials() throws {
        let app = XCUIApplication()
        app.launch()

        // Should show login page initially
        XCTAssertTrue(app.textFields["Email"].exists)

        // Fill in test credentials
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("tester@example.com")

        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("test123")

        app.buttons["Sign In (Test)"].tap()

        // Should navigate to main app
        // (You'll need to add accessibility identifiers to your ContentView)
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppleSignInButtonExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Apple Sign In button should be present
        XCTAssertTrue(app.buttons["Sign in with Apple"].exists)
    }
}
