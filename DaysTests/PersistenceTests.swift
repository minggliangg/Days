//
//  PersistenceTests.swift
//  DaysTests
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import Testing
import SwiftData
@testable import Days

@Suite("Persistence Tests")
struct PersistenceTests {

    // MARK: - Insert Tests

    @Test("Insert countdown should persist in modelContext")
    @MainActor
    func insertCountdownPersists() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown = Countdown(name: "Birthday", targetDate: Date(), includeTime: true)
        modelContext.insert(countdown)
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Birthday")
        #expect(fetched.first?.includeTime == true)
    }

    @Test("Insert multiple countdowns should all persist")
    @MainActor
    func insertMultipleCountdownsPersist() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown1 = Countdown(name: "Event 1", targetDate: Date())
        let countdown2 = Countdown(name: "Event 2", targetDate: Date().addingTimeInterval(86400))
        let countdown3 = Countdown(name: "Event 3", targetDate: Date().addingTimeInterval(172800))

        modelContext.insert(countdown1)
        modelContext.insert(countdown2)
        modelContext.insert(countdown3)
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.count == 3)
    }

    // MARK: - Update Tests

    @Test("Update countdown should persist changes")
    @MainActor
    func updateCountdownPersistsChanges() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown = Countdown(name: "Original", targetDate: Date())
        modelContext.insert(countdown)
        try modelContext.save()

        countdown.name = "Updated"
        countdown.includeTime = true
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.first?.name == "Updated")
        #expect(fetched.first?.includeTime == true)
    }

    // MARK: - Delete Tests

    @Test("Delete countdown should remove from modelContext")
    @MainActor
    func deleteCountdownRemoves() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown = Countdown(name: "To Delete", targetDate: Date())
        modelContext.insert(countdown)
        try modelContext.save()

        modelContext.delete(countdown)
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.isEmpty)
    }

    @Test("Delete one countdown should not affect others")
    @MainActor
    func deleteOneCountdownKeepsOthers() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let countdown1 = Countdown(name: "Keep", targetDate: Date())
        let countdown2 = Countdown(name: "Delete", targetDate: Date())

        modelContext.insert(countdown1)
        modelContext.insert(countdown2)
        try modelContext.save()

        modelContext.delete(countdown2)
        try modelContext.save()

        let descriptor = FetchDescriptor<Countdown>()
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Keep")
    }

    // MARK: - Sort Order Tests

    @Test("Countdowns should be sortable by targetDate")
    @MainActor
    func countdownsSortedByTargetDate() async throws {
        let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
        let modelContext = container.mainContext

        let date1 = Date().addingTimeInterval(172800) // 2 days from now
        let date2 = Date().addingTimeInterval(86400)  // 1 day from now
        let date3 = Date()                            // today

        let countdown1 = Countdown(name: "Future", targetDate: date1)
        let countdown2 = Countdown(name: "Tomorrow", targetDate: date2)
        let countdown3 = Countdown(name: "Today", targetDate: date3)

        modelContext.insert(countdown1)
        modelContext.insert(countdown2)
        modelContext.insert(countdown3)
        try modelContext.save()

        var descriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.targetDate)])
        let fetched = try modelContext.fetch(descriptor)

        #expect(fetched.count == 3)
        #expect(fetched[0].name == "Today")
        #expect(fetched[1].name == "Tomorrow")
        #expect(fetched[2].name == "Future")
    }

    // MARK: - Model Property Tests

    @Test("Countdown should store all properties correctly")
    @MainActor
    func countdownStoresPropertiesCorrectly() async throws {
        let targetDate = Date()
        let countdown = Countdown(name: "Test Event", targetDate: targetDate, includeTime: true)

        #expect(countdown.name == "Test Event")
        #expect(countdown.targetDate == targetDate)
        #expect(countdown.includeTime == true)
    }

    @Test("Countdown includeTime should default to false")
    @MainActor
    func countdownIncludeTimeDefaultsToFalse() async throws {
        let countdown = Countdown(name: "Test", targetDate: Date())

        #expect(countdown.includeTime == false)
    }
}
