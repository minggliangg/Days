//
//  HomeViewModelTests.swift
//  DaysTests
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import Testing
import SwiftData
import SwiftUI
@testable import Days

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    // MARK: - Delete Tests

    @Test("Delete should remove countdown from modelContext")
    @MainActor
    func deleteRemovesCountdown() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "To Delete", targetDate: Date())
        modelContext.insert(countdown)
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        #expect(try modelContext.fetch(descriptor).count == 1)

        viewModel.deleteCountdown(countdown)

        #expect(try modelContext.fetch(descriptor).isEmpty, "Countdown should be deleted")
    }

    // MARK: - Navigation Tests

    @Test("Navigate to detail should add item to navigation path")
    @MainActor
    func navigateToDetailAddsDestination() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test", targetDate: Date())
        modelContext.insert(countdown)

        #expect(viewModel.navigationPath.isEmpty)

        viewModel.navigateToDetail(countdown)

        #expect(viewModel.navigationPath.count == 1, "Navigation path should have one item")
        #expect(viewModel.navigationPath == [.detail(countdownID: countdown.persistentModelID)])
    }

    @Test("Navigate to edit should add item to navigation path")
    @MainActor
    func navigateToEditAddsDestination() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test", targetDate: Date())
        modelContext.insert(countdown)

        #expect(viewModel.navigationPath.isEmpty)

        viewModel.navigateToEdit(countdown)

        #expect(viewModel.navigationPath.count == 1, "Navigation path should have one item")
        #expect(viewModel.navigationPath == [.edit(countdownID: countdown.persistentModelID)])
    }

    @Test("Navigate to add should add item to navigation path")
    @MainActor
    func navigateToAddAddsDestination() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        #expect(viewModel.navigationPath.isEmpty)

        viewModel.navigateToAdd()

        #expect(viewModel.navigationPath.count == 1, "Navigation path should have one item")
        #expect(viewModel.navigationPath == [.add])
    }

    @Test("Pop should remove last item from navigation path")
    @MainActor
    func popRemovesLastItem() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        viewModel.navigateToAdd()
        #expect(viewModel.navigationPath.count == 1)

        viewModel.pop()

        #expect(viewModel.navigationPath.isEmpty)
    }

    @Test("Pop should do nothing when path is empty")
    @MainActor
    func popDoesNothingWhenEmpty() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        #expect(viewModel.navigationPath.isEmpty)

        viewModel.pop()

        #expect(viewModel.navigationPath.isEmpty, "Pop on empty path should be a no-op")
    }

    @Test("Pop and navigate to detail should maintain one item in path")
    @MainActor
    func popAndNavigateToDetail() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)
        let countdown = Countdown(name: "Test", targetDate: Date())
        modelContext.insert(countdown)

        viewModel.navigateToEdit(countdown)
        #expect(viewModel.navigationPath.count == 1)

        viewModel.popAndNavigateToDetail(countdown)

        #expect(viewModel.navigationPath.count == 1, "Should have one item after pop and navigate")
        #expect(viewModel.navigationPath == [.detail(countdownID: countdown.persistentModelID)])
    }

    @Test("Pop and navigate to detail should not duplicate existing detail destination")
    @MainActor
    func popAndNavigateToDetailDoesNotDuplicateDetail() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)
        let countdown = Countdown(name: "Test", targetDate: Date())
        modelContext.insert(countdown)

        viewModel.navigateToDetail(countdown)
        viewModel.navigateToEdit(countdown)
        #expect(viewModel.navigationPath.count == 2)

        viewModel.popAndNavigateToDetail(countdown)

        #expect(viewModel.navigationPath == [.detail(countdownID: countdown.persistentModelID)])
    }

    @Test("Multiple navigation calls should stack items in path")
    @MainActor
    func multipleNavigationCallsStack() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test", targetDate: Date())
        modelContext.insert(countdown)

        viewModel.navigateToAdd()
        viewModel.navigateToDetail(countdown)
        viewModel.navigateToEdit(countdown)

        #expect(viewModel.navigationPath.count == 3, "Navigation path should stack multiple items")
    }

    // MARK: - Fetch Tests

    @Test("Fetch countdown by ID should return correct countdown")
    @MainActor
    func fetchCountdownById() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test Event", targetDate: Date())
        modelContext.insert(countdown)
        try modelContext.save()

        let fetched = viewModel.fetchCountdown(by: countdown.persistentModelID)

        #expect(fetched?.name == "Test Event")
        #expect(fetched?.persistentModelID == countdown.persistentModelID)
    }

    @Test("Fetch countdown by UUID should return correct countdown")
    @MainActor
    func fetchCountdownByUUID() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let countdown = Countdown(name: "Test Event", targetDate: Date())
        modelContext.insert(countdown)
        try modelContext.save()

        let fetched = try viewModel.fetchCountdown(by: countdown.id)

        #expect(fetched?.name == "Test Event")
        #expect(fetched?.id == countdown.id)
    }

    @Test("Fetch countdown by non-existent UUID should return nil")
    @MainActor
    func fetchCountdownByNonExistentUUIDReturnsNil() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let viewModel = HomeViewModel(modelContext: modelContext)

        let nonExistentID = UUID()
        let fetched = try viewModel.fetchCountdown(by: nonExistentID)

        #expect(fetched == nil, "Should return nil for non-existent UUID")
    }

    @Test("Assign missing countdown UUIDs should backfill existing records")
    @MainActor
    func assignMissingCountdownUUIDsBackfillsExistingRecords() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown = Countdown(name: "Legacy Event", targetDate: Date())
        countdown.id = nil
        modelContext.insert(countdown)
        try modelContext.save()

        try SharedModelContainer.assignMissingCountdownIDsIfNeeded(in: modelContext)

        #expect(countdown.id != nil)
    }
}
