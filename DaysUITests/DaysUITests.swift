//
//  DaysUITests.swift
//  DaysUITests
//
//  Smoke test suite for UI validation.
//  Tests are designed to be fast, deterministic, and use seeded data.
//

import XCTest

final class DaysUITests: UITestBase {

    // MARK: - Launch Tests

    @MainActor
    func testAppLaunchesAndShowsHomeScreen() throws {
        // Given: App launched with empty state
        launchWithEmptyState()

        // Then: Home screen is displayed
        let navigationBar = app.navigationBars["Days"]
        XCTAssertTrue(navigationBar.exists, "Home screen navigation bar should be visible")

        // And: Add button exists
        XCTAssertTrue(addButton.exists, "Add button should be visible on home screen")
    }

    // MARK: - Add Menu Tests

    @MainActor
    func testAddMenuOpensCountdownFlow() throws {
        // Given: App launched with empty state
        launchWithEmptyState()

        // When: Opening add menu and selecting Countdown
        addButton.tap()

        // Then: Countdown menu item should exist
        XCTAssertTrue(
            countdownMenuItem.waitForExistence(timeout: 1),
            "Countdown menu item should appear"
        )
    }

    @MainActor
    func testAddMenuOpensOccasionFlow() throws {
        // Given: App launched with empty state
        launchWithEmptyState()

        // When: Opening add menu
        addButton.tap()

        // Then: Occasion menu item should exist
        XCTAssertTrue(
            occasionMenuItem.waitForExistence(timeout: 1),
            "Occasion menu item should appear"
        )
    }

    // MARK: - Create Flow Tests (Empty State)

    @MainActor
    func testCreateCountdownHappyPath() throws {
        // Given: App launched with empty state
        launchWithEmptyState()

        // When: Creating a countdown
        openAddCountdownMenu()

        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Title field should appear")
        titleField.tap()
        titleField.typeText("My Birthday")

        formAddButton.tap()

        // Then: Countdown appears in list
        XCTAssertTrue(
            waitForEntry(named: "My Birthday"),
            "Created countdown should appear in list"
        )
    }

    @MainActor
    func testCreateOccasionHappyPath() throws {
        // Given: App launched with empty state
        launchWithEmptyState()

        // When: Creating an occasion
        openAddOccasionMenu()

        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Title field should appear")
        titleField.tap()
        titleField.typeText("Birthday")

        personField.tap()
        personField.typeText("John Doe")

        formAddButton.tap()

        // Then: Occasion appears in list
        XCTAssertTrue(
            waitForEntry(named: "Birthday"),
            "Created occasion should appear in list"
        )
    }

    // MARK: - Navigation Tests (Seeded Data)

    @MainActor
    func testNavigateToDetailFromSeededData() throws {
        // Given: App launched with single countdown
        launchWithSingleCountdown()

        // When: Tapping on the countdown
        let entry = entryRow(named: "Test Countdown")
        XCTAssertTrue(entry.waitForExistence(timeout: 2), "Seeded countdown should exist")
        entry.tap()

        // Then: Detail view is shown
        let detailNavBar = app.navigationBars["Test Countdown"]
        XCTAssertTrue(
            detailNavBar.waitForExistence(timeout: 2),
            "Detail view should show countdown name"
        )

        // And: Edit button exists
        let editButton = app.buttons["pencil"]
        XCTAssertTrue(editButton.exists, "Edit button should be visible in detail view")
    }

    // MARK: - Filter Tests (Seeded Data)

    @MainActor
    func testFilterFromSeededMixedData() throws {
        // Given: App launched with mixed data
        launchWithMixedData()

        // Then: Both entries should be visible
        XCTAssertTrue(
            waitForEntry(named: "Vacation"),
            "Countdown should be visible"
        )
        XCTAssertTrue(
            waitForEntry(named: "Birthday"),
            "Occasion should be visible"
        )

        // When: Tapping Occasions filter
        XCTAssertTrue(occasionsFilterChip.exists, "Occasions filter should exist")
        occasionsFilterChip.tap()

        // Then: Only occasion should be visible
        XCTAssertFalse(
            entryRow(named: "Vacation").exists,
            "Countdown should be filtered out"
        )
        XCTAssertTrue(
            entryRow(named: "Birthday").exists,
            "Occasion should still be visible"
        )
    }
}
