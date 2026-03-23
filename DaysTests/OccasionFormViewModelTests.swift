//
//  OccasionFormViewModelTests.swift
//  DaysTests
//
//  Unit tests for OccasionFormViewModel covering validation, save/update,
//  iteration mode, and navigation effects.
//

import Foundation
import Testing
import SwiftData
import SwiftUI
@testable import Days

@Suite("OccasionFormViewModel Tests")
struct OccasionFormViewModelTests {

    // MARK: - Form Validation Tests

    @Test("Empty title should be invalid")
    @MainActor
    func emptyTitleIsInvalid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = ""

        #expect(!viewModel.isValid, "Empty title should make form invalid")
    }

    @Test("Non-empty title should be valid")
    @MainActor
    func nonEmptyTitleIsValid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Birthday Party"

        #expect(viewModel.isValid, "Non-empty title should make form valid")
    }

    // MARK: - isEditing Tests

    @Test("isEditing should be false when creating new occasion")
    @MainActor
    func isEditingFalseForNewOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        #expect(!viewModel.isEditing, "Should not be in editing mode for new occasion")
    }

    @Test("isEditing should be true when editing existing occasion")
    @MainActor
    func isEditingTrueForExistingOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let occasion = Occasion(
            title: "Existing",
            occasionType: .birthday,
            personName: "John",
            month: 3,
            day: 15,
            startYear: 1990,
            iconName: nil,
            category: nil
        )
        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.isEditing, "Should be in editing mode for existing occasion")
    }

    // MARK: - Initialization Tests

    @Test("ViewModel should initialize with empty values for new occasion")
    @MainActor
    func initializesWithEmptyValuesForNewOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.title == "")
        #expect(viewModel.occasionType == .birthday)
        #expect(viewModel.personName == nil)
        #expect(viewModel.iterationMode == .derived)
        #expect(viewModel.manualIteration == 1)
        #expect(viewModel.iconName == nil)
        #expect(viewModel.selectedCategory == nil)
    }

    @Test("ViewModel should initialize with occasion values when editing")
    @MainActor
    func initializesWithOccasionValuesWhenEditing() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let category = Category(name: "Family", colorHex: "#FF0000", sortOrder: 0)
        let occasion = Occasion(
            title: "Wedding Anniversary",
            occasionType: .anniversary,
            personName: "Jane",
            month: 6,
            day: 20,
            startYear: 2015,
            iconName: "heart",
            category: category
        )
        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.title == "Wedding Anniversary")
        #expect(viewModel.occasionType == .anniversary)
        #expect(viewModel.personName == "Jane")
        #expect(viewModel.iconName == "heart")
        #expect(viewModel.selectedCategory?.name == "Family")
    }

    // MARK: - Iteration Mode Tests

    @Test("Derived iteration mode should use year from selected date")
    @MainActor
    func derivedModeUsesYearFromDate() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Birthday"
        viewModel.iterationMode = .derived

        // Set a specific date
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1990
        components.month = 5
        components.day = 15
        viewModel.selectedDate = calendar.date(from: components) ?? Date()

        viewModel.save()

        let descriptor = FetchDescriptor<Occasion>()
        let occasions = try modelContext.fetch(descriptor)

        #expect(occasions.count == 1)
        #expect(occasions.first?.startYear == 1990)
        #expect(occasions.first?.month == 5)
        #expect(occasions.first?.day == 15)
    }

    @Test("Manual iteration mode should calculate start year from next occurrence")
    @MainActor
    func manualModeCalculatesStartYear() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Birthday"
        viewModel.iterationMode = .manual
        viewModel.manualIteration = 30

        // Set date to a future date (so next occurrence is clearly this year)
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        // Use a date 6 months in the future to ensure it's clearly after "now"
        var futureComponents = calendar.dateComponents([.year, .month, .day], from: now)
        futureComponents.month! += 6
        if futureComponents.month! > 12 {
            futureComponents.month! -= 12
            futureComponents.year! += 1
        }
        let futureDate = calendar.date(from: futureComponents) ?? now
        viewModel.selectedDate = futureDate

        viewModel.save()

        let descriptor = FetchDescriptor<Occasion>()
        let occasions = try modelContext.fetch(descriptor)

        #expect(occasions.count == 1)

        // Extract month/day from the selected date
        let month = calendar.component(.month, from: futureDate)
        let day = calendar.component(.day, from: futureDate)

        // Calculate expected next occurrence year
        let nextOccurrenceYear: Int
        let testComps = DateComponents(year: currentYear, month: month, day: day)
        if let testDate = calendar.date(from: testComps), testDate >= now {
            nextOccurrenceYear = currentYear
        } else {
            nextOccurrenceYear = currentYear + 1
        }

        let expectedStartYear = nextOccurrenceYear - 30
        #expect(occasions.first?.startYear == expectedStartYear)
    }

    // MARK: - Save Behavior Tests

    @Test("Save should insert new occasion into modelContext")
    @MainActor
    func saveInsertsNewOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Mom's Birthday"
        viewModel.occasionType = .birthday
        viewModel.personName = "Mom"
        viewModel.selectIcon("gift")

        viewModel.save()

        let descriptor = FetchDescriptor<Occasion>()
        let occasions = try modelContext.fetch(descriptor)

        #expect(occasions.count == 1)
        #expect(occasions.first?.title == "Mom's Birthday")
        #expect(occasions.first?.occasionType == .birthday)
        #expect(occasions.first?.personName == "Mom")
        #expect(occasions.first?.iconName == "gift")
    }

    @Test("Save should not insert when title is empty")
    @MainActor
    func saveDoesNotInsertWhenInvalid() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = ""
        viewModel.save()

        let descriptor = FetchDescriptor<Occasion>()
        let occasions = try modelContext.fetch(descriptor)

        #expect(occasions.isEmpty, "Should not insert occasion with empty title")
    }

    @Test("Save should update existing occasion")
    @MainActor
    func saveUpdatesExistingOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let occasion = Occasion(
            title: "Original Title",
            occasionType: .birthday,
            personName: "Original Person",
            month: 3,
            day: 15,
            startYear: 1990,
            iconName: "gift",
            category: nil
        )
        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Updated Title"
        viewModel.occasionType = .anniversary
        viewModel.personName = "Updated Person"
        viewModel.selectIcon("heart")

        viewModel.save()

        #expect(occasion.title == "Updated Title")
        #expect(occasion.occasionType == .anniversary)
        #expect(occasion.personName == "Updated Person")
        #expect(occasion.iconName == "heart")
    }

    // MARK: - Navigation Tests

    @Test("Save should trigger navigation pop for new occasion")
    @MainActor
    func saveTriggersNavigationPopForNewOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        // Simulate being on add screen (path has 1 item)
        homeViewModel.navigateToAddOccasion()

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Test"
        viewModel.save()

        #expect(homeViewModel.navigationPath.isEmpty, "Navigation path should be cleared after save")
    }

    @Test("Save should navigate to detail for existing occasion")
    @MainActor
    func saveNavigatesToDetailForExistingOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let occasion = Occasion(
            title: "Test",
            occasionType: .birthday,
            personName: nil,
            month: 1,
            day: 1,
            startYear: 2000,
            iconName: nil,
            category: nil
        )
        homeViewModel.navigateToOccasionEdit(occasion)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Updated"
        viewModel.save()

        // After save, we should navigate to occasion detail
        #expect(homeViewModel.navigationPath.count == 1, "Should navigate to detail after save")
        #expect(homeViewModel.navigationPath == [.occasionDetail(occasionID: occasion.persistentModelID)])
    }

    // MARK: - Icon Selection Tests

    @Test("Select icon should update iconName")
    @MainActor
    func selectIconUpdatesIconName() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.selectIcon("birthday.cake")
        #expect(viewModel.iconName == "birthday.cake")

        viewModel.selectIcon(nil)
        #expect(viewModel.iconName == nil)
    }

    // MARK: - Category Tests

    @Test("Save should persist category relationship")
    @MainActor
    func savePersistsCategoryRelationship() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let category = Category(name: "Work", colorHex: "#0000FF", sortOrder: 0)
        modelContext.insert(category)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        viewModel.title = "Work Anniversary"
        viewModel.selectedCategory = category

        viewModel.save()

        let descriptor = FetchDescriptor<Occasion>()
        let occasions = try modelContext.fetch(descriptor)

        #expect(occasions.count == 1)
        #expect(occasions.first?.category?.name == "Work")
    }
}

@Suite("OccasionFormViewModel Iteration Mode Tests")
struct OccasionFormViewModelIterationModeTests {

    @Test("Derived mode should be default for new occasion")
    @MainActor
    func derivedModeIsDefault() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.iterationMode == .derived)
    }

    @Test("Derived mode should be default when editing existing occasion")
    @MainActor
    func derivedModeIsDefaultWhenEditing() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let occasion = Occasion(
            title: "Test",
            occasionType: .birthday,
            personName: nil,
            month: 1,
            day: 1,
            startYear: 2000,
            iconName: nil,
            category: nil
        )
        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.iterationMode == .derived)
    }

    @Test("Manual iteration default should be 1 for new occasion")
    @MainActor
    func manualIterationDefaultIsOne() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: nil,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.manualIteration == 1)
    }

    @Test("Manual iteration should initialize from occasion's next iteration")
    @MainActor
    func manualIterationInitializesFromOccasion() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext
        let homeViewModel = HomeViewModel(modelContext: modelContext)

        // Create an occasion that will have nextIteration of 30
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let occasion = Occasion(
            title: "30th Birthday",
            occasionType: .birthday,
            personName: nil,
            month: 1,
            day: 1,
            startYear: currentYear - 29, // Will be 30th birthday this year
            iconName: nil,
            category: nil
        )
        let viewModel = OccasionFormViewModel(
            modelContext: modelContext,
            occasion: occasion,
            navigationViewModel: homeViewModel
        )

        #expect(viewModel.manualIteration == occasion.nextIteration)
    }
}
