//
//  UITestBase.swift
//  DaysUITests
//
//  Base class for UI tests providing launch, reset, and seed utilities.
//

import XCTest

/// Launch arguments for UI testing (mirrors SharedModelContainer.UITestArgument)
enum UITestArgument {
    static let uiTesting = "--uitesting"
    static let inMemory = "--in-memory"
    static let reset = "--reset"
    static let seed = "--seed"
}

/// Seed scenarios for UI tests (mirrors SharedModelContainer.SeedScenario)
enum SeedScenario: String {
    case empty
    case singleCountdown
    case singleOccasion
    case mixed
}

class UITestBase: XCTestCase {
    var app: XCUIApplication!

    // MARK: - Launch Configuration

    /// Launch the app with UI testing mode and optional seed scenario
    func launchApp(seed: SeedScenario = .empty) {
        app = XCUIApplication()
        app.launchArguments = [
            UITestArgument.uiTesting,
            UITestArgument.inMemory,
            UITestArgument.seed,
            seed.rawValue
        ]
        app.launch()
    }

    /// Launch the app with empty state (default)
    func launchWithEmptyState() {
        launchApp(seed: .empty)
    }

    /// Launch the app with a single countdown pre-seeded
    func launchWithSingleCountdown() {
        launchApp(seed: .singleCountdown)
    }

    /// Launch the app with a single occasion pre-seeded
    func launchWithSingleOccasion() {
        launchApp(seed: .singleOccasion)
    }

    /// Launch the app with mixed entries (countdowns and occasions)
    func launchWithMixedData() {
        launchApp(seed: .mixed)
    }

    // MARK: - Helper Properties

    /// The add button in the home screen
    var addButton: XCUIElement {
        app.buttons["add_button"]
    }

    /// The countdown menu item
    var countdownMenuItem: XCUIElement {
        app.buttons["menu_countdown"]
    }

    /// The occasion menu item
    var occasionMenuItem: XCUIElement {
        app.buttons["menu_occasion"]
    }

    /// The title text field in forms
    var titleField: XCUIElement {
        app.textFields["title_field"]
    }

    /// The person name field in occasion form
    var personField: XCUIElement {
        app.textFields["person_field"]
    }

    /// The add button in form toolbar
    var formAddButton: XCUIElement {
        app.buttons["add_button"]
    }

    /// The save button in form toolbar
    var formSaveButton: XCUIElement {
        app.buttons["save_button"]
    }

    /// The "All" filter chip
    var allFilterChip: XCUIElement {
        app.buttons["filter_all"]
    }

    /// The "Occasions" filter chip
    var occasionsFilterChip: XCUIElement {
        app.buttons["filter_occasions"]
    }

    // MARK: - Helper Methods

    /// Open the add menu and select Countdown
    func openAddCountdownMenu() {
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add button should exist")
        addButton.tap()

        // Wait for menu to appear and tap countdown item
        let menu = app.menuItems["menu_countdown"]
        if menu.waitForExistence(timeout: 1) {
            menu.tap()
        } else {
            // Fallback to button
            let button = app.buttons["menu_countdown"]
            XCTAssertTrue(button.waitForExistence(timeout: 1), "Countdown menu item should exist")
            button.tap()
        }
    }

    /// Open the add menu and select Occasion
    func openAddOccasionMenu() {
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add button should exist")
        addButton.tap()

        // Wait for menu to appear and tap occasion item
        let menu = app.menuItems["menu_occasion"]
        if menu.waitForExistence(timeout: 1) {
            menu.tap()
        } else {
            // Fallback to button
            let button = app.buttons["menu_occasion"]
            XCTAssertTrue(button.waitForExistence(timeout: 1), "Occasion menu item should exist")
            button.tap()
        }
    }

    /// Create a countdown with the given name
    func createCountdown(name: String) {
        openAddCountdownMenu()

        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Title field should appear")
        titleField.tap()
        titleField.typeText(name)

        XCTAssertTrue(formAddButton.exists, "Add button should exist")
        formAddButton.tap()
    }

    /// Create an occasion with the given title and optional person name
    func createOccasion(title: String, personName: String? = nil) {
        openAddOccasionMenu()

        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Title field should appear")
        titleField.tap()
        titleField.typeText(title)

        if let personName = personName, !personName.isEmpty {
            XCTAssertTrue(personField.waitForExistence(timeout: 1), "Person field should appear")
            personField.tap()
            personField.typeText(personName)
        }

        XCTAssertTrue(formAddButton.exists, "Add button should exist")
        formAddButton.tap()
    }

    /// Get an entry row by name
    func entryRow(named name: String) -> XCUIElement {
        app.buttons["entry_\(name)"]
    }

    /// Wait for an entry to appear in the list
    func waitForEntry(named name: String, timeout: TimeInterval = 2) -> Bool {
        entryRow(named: name).waitForExistence(timeout: timeout)
    }

    /// Navigate back to home screen
    func navigateBack() {
        let backButton = app.buttons["Days"]
        if backButton.exists {
            backButton.tap()
        }
    }
}
