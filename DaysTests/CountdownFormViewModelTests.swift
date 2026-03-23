//
//  CountdownFormViewModelTests.swift
//  DaysTests
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import Testing
import SwiftData
import SwiftUI
@testable import Days

@Suite("CountdownFormViewModel Tests")
struct CountdownFormViewModelTests {

    // MARK: - Form Validation Tests

    @Test("Empty name should be invalid")
    @MainActor
    func emptyNameIsInvalid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = ""

        #expect(!viewModel.isValid, "Empty name should make form invalid")
    }

    @Test("Non-empty name should be valid")
    @MainActor
    func nonEmptyNameIsValid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = "My Birthday"

        #expect(viewModel.isValid, "Non-empty name should make form valid")
    }

    // MARK: - isEditing Tests

    @Test("isEditing should be false when creating new countdown")
    @MainActor
    func isEditingFalseForNewCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        #expect(!viewModel.isEditing, "Should not be in editing mode for new countdown")
    }

    @Test("isEditing should be true when editing existing countdown")
    @MainActor
    func isEditingTrueForExistingCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Existing", targetDate: Date())
        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        #expect(viewModel.isEditing, "Should be in editing mode for existing countdown")
    }

    // MARK: - Initialization Tests

    @Test("ViewModel should initialize with empty values for new countdown")
    @MainActor
    func initializesWithEmptyValuesForNewCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        #expect(viewModel.name == "")
        #expect(viewModel.includeTime == false)
    }

    @Test("ViewModel should initialize with countdown values when editing")
    @MainActor
    func initializesWithCountdownValuesWhenEditing() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let targetDate = Date().addingTimeInterval(86400) // Tomorrow
        let countdown = Countdown(name: "Test Event", targetDate: targetDate, includeTime: true)
        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        #expect(viewModel.name == "Test Event")
        #expect(viewModel.includeTime == true)
        #expect(viewModel.targetDate == targetDate)
    }

    @Test("ViewModel should initialize icon values when editing")
    @MainActor
    func initializesWithIconWhenEditing() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Trip", targetDate: Date())
        countdown.iconName = "airplane"

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        #expect(viewModel.iconName == "airplane")
    }

    // MARK: - Save Behavior Tests

    @Test("Save should insert new countdown into modelContext")
    @MainActor
    func saveInsertsNewCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = "New Year Party"
        viewModel.targetDate = Date()
        viewModel.includeTime = true
        viewModel.selectIcon("party.popper")

        viewModel.save()

        // Fetch all countdowns to verify insertion
        let descriptor = FetchDescriptor<Countdown>()
        let countdowns = try modelContext.fetch(descriptor)

        #expect(countdowns.count == 1)
        #expect(countdowns.first?.name == "New Year Party")
        #expect(countdowns.first?.includeTime == true)
        #expect(countdowns.first?.iconName == "party.popper")
    }

    @Test("Save should not insert when name is empty")
    @MainActor
    func saveDoesNotInsertWhenInvalid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = ""
        viewModel.save()

        let descriptor = FetchDescriptor<Countdown>()
        let countdowns = try modelContext.fetch(descriptor)

        #expect(countdowns.isEmpty, "Should not insert countdown with empty name")
    }

    @Test("Save should update existing countdown")
    @MainActor
    func saveUpdatesExistingCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Original Name", targetDate: Date())
        countdown.iconName = "airplane"
        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = "Updated Name"
        viewModel.includeTime = true
        viewModel.selectIcon("gift")

        viewModel.save()

        #expect(countdown.name == "Updated Name")
        #expect(countdown.includeTime == true)
        #expect(countdown.iconName == "gift")
    }

    // MARK: - Navigation Tests

    @Test("Save should trigger navigation pop for new countdown")
    @MainActor
    func saveTriggersNavigationPopForNewCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        // Simulate being on add screen (path has 1 item)
        homeViewModel.navigateToAdd()

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: nil,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.name = "Test"
        viewModel.save()

        #expect(homeViewModel.navigationPath.isEmpty, "Navigation path should be cleared after save")
    }

    @Test("Save should navigate to detail when navigateToDetailOnSave is true")
    @MainActor
    func saveNavigatesToDetailWhenConfigured() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        // Simulate being on edit screen (path has 1 item)
        let countdown = Countdown(name: "Test", targetDate: Date())
        homeViewModel.navigateToEdit(countdown)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: true
        )

        viewModel.name = "Updated"
        viewModel.save()

        // After save with navigateToDetailOnSave = true, we should have 1 item in path
        // (popped from edit, then navigated to detail)
        #expect(homeViewModel.navigationPath.count == 1, "Should navigate to detail after save")
        #expect(homeViewModel.navigationPath == [.detail(countdownID: countdown.persistentModelID)])
    }

    @Test("Save from detail edit should return to the existing detail screen")
    @MainActor
    func saveFromDetailEditDoesNotDuplicateDetail() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test", targetDate: Date())
        homeViewModel.navigateToDetail(countdown)
        homeViewModel.navigateToEdit(countdown)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: true
        )

        viewModel.name = "Updated"
        viewModel.save()

        #expect(homeViewModel.navigationPath == [.detail(countdownID: countdown.persistentModelID)])
    }

    @Test("Saving an overdue recurring countdown should advance it immediately")
    @MainActor
    func saveAdvancesOverdueRecurringCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let overdueDate = Date().addingTimeInterval(-49 * 60 * 60)
        let countdown = Countdown(name: "Recurring", targetDate: overdueDate)
        countdown.isRecurring = true
        countdown.intervalType = .daily
        countdown.initialTargetDate = overdueDate
        modelContext.insert(countdown)

        let viewModel = CountdownFormViewModel(
            modelContext: modelContext,
            countdown: countdown,
            navigationViewModel: homeViewModel,
            navigateToDetailOnSave: false
        )

        viewModel.save()

        #expect(countdown.targetDate > Date(), "Overdue recurring countdown should be advanced to the next future occurrence")
    }
}

@Suite("CountdownDetail recurrence math")
struct CountdownDetailRecurrenceMathTests {
    @Test("Occurrence count should include the current occurrence")
    func occurrenceCountIncludesCurrentOccurrence() {
        let initialDate = Date(timeIntervalSince1970: 0)
        let targetDate = Date(timeIntervalSince1970: 86400)

        let count = recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: targetDate,
            intervalType: .daily,
            customDays: nil,
            occasionType: nil
        )

        #expect(count == 2)
    }

    @Test("Custom recurrence count should use the configured interval")
    func customOccurrenceCountUsesConfiguredInterval() {
        let initialDate = Date(timeIntervalSince1970: 0)
        let targetDate = Date(timeIntervalSince1970: 4 * 86400)

        let count = recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: targetDate,
            intervalType: .custom,
            customDays: 2,
            occasionType: nil
        )

        #expect(count == 3)
    }

    @Test("Annual birthday count should start at zero")
    func annualBirthdayCountStartsAtZero() {
        let initialDate = Date(timeIntervalSince1970: 0)
        let targetDate = initialDate

        let count = recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: targetDate,
            intervalType: .annually,
            customDays: nil,
            occasionType: .birthday
        )

        #expect(count == 0)
    }

    @Test("Annual birthday count should advance to one after a year")
    func annualBirthdayCountAdvancesToOne() {
        let initialDate = Date(timeIntervalSince1970: 0)
        let targetDate = Date(timeIntervalSince1970: 365 * 86400)

        let count = recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: targetDate,
            intervalType: .annually,
            customDays: nil,
            occasionType: .birthday
        )

        #expect(count == 1)
    }

    @Test("Annual anniversary count should start at zero")
    func annualAnniversaryCountStartsAtZero() {
        let initialDate = Date(timeIntervalSince1970: 0)
        let targetDate = initialDate

        let count = recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: targetDate,
            intervalType: .annually,
            customDays: nil,
            occasionType: .anniversary
        )

        #expect(count == 0)
    }
}
