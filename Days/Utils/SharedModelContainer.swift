//
//  SharedModelContainer.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftData
import Foundation
import WidgetKit

enum SharedModelContainer {
    static let appGroupID = "group.com.minggliangg.Days"

    /// Launch arguments for UI testing
    enum UITestArgument {
        static let uiTesting = "--uitesting"
        static let inMemory = "--in-memory"
        static let reset = "--reset"
        static let seed = "--seed"
    }

    /// Seed scenarios for UI tests
    enum SeedScenario: String {
        case empty
        case singleCountdown
        case singleOccasion
        case mixed
    }

    static func makeContainer(useInMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Countdown.self, Category.self, Occasion.self])

        if useInMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }

        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw SharedContainerError.missingEntitlement
        }
        let storeURL = containerURL.appendingPathComponent("Days.store")

        let config = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [config])
    }

    static var sharedContainer: ModelContainer?

    @discardableResult
    static func initializeContainer() throws -> ModelContainer {
        // Check for UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains(UITestArgument.uiTesting)
        let useInMemory = isUITesting || ProcessInfo.processInfo.arguments.contains(UITestArgument.inMemory)
        let shouldReset = ProcessInfo.processInfo.arguments.contains(UITestArgument.reset)

        // Get seed scenario if specified
        let seedScenario: SeedScenario? = {
            guard let seedIndex = ProcessInfo.processInfo.arguments.firstIndex(of: UITestArgument.seed),
                  seedIndex + 1 < ProcessInfo.processInfo.arguments.count else {
                return nil
            }
            return SeedScenario(rawValue: ProcessInfo.processInfo.arguments[seedIndex + 1])
        }()

        // Reset persistent storage if requested (only for non-in-memory)
        if shouldReset && !useInMemory {
            resetPersistentStorage()
        }

        let container = try makeContainer(useInMemory: useInMemory)
        sharedContainer = container
        let context = ModelContext(container)

        // Skip migrations and auto-advancement in UI test mode with seeding
        if !isUITesting {
            try assignMissingCountdownIDsIfNeeded(in: context)
            try migrateExistingOccasionsIfNeeded(in: context)
            RecurringAdvancer.advanceIfNeeded(in: context)
        }

        // Seed data for UI tests
        if isUITesting, let scenario = seedScenario {
            seedData(for: scenario, in: context)
        }

        return container
    }

    /// Reset persistent storage by deleting the store file
    static func resetPersistentStorage() {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return
        }
        let storeURL = containerURL.appendingPathComponent("Days.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    /// Seed test data for UI tests
    static func seedData(for scenario: SeedScenario, in context: ModelContext) {
        let calendar = Calendar.current

        switch scenario {
        case .empty:
            break

        case .singleCountdown:
            let countdown = Countdown(
                name: "Test Countdown",
                targetDate: calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                includeTime: false
            )
            countdown.id = UUID()
            context.insert(countdown)

        case .singleOccasion:
            let occasion = Occasion(
                title: "Test Occasion",
                occasionType: .birthday,
                personName: "Test Person",
                month: calendar.component(.month, from: Date()),
                day: calendar.component(.day, from: Date()),
                startYear: calendar.component(.year, from: Date()) - 30,
                iconName: nil,
                category: nil
            )
            context.insert(occasion)

        case .mixed:
            // Add a category
            let category = Category(name: "Personal", colorHex: "#FF5733", sortOrder: 0)
            context.insert(category)

            // Add countdowns
            let countdown1 = Countdown(
                name: "Vacation",
                targetDate: calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                includeTime: false
            )
            countdown1.id = UUID()
            countdown1.category = category
            context.insert(countdown1)

            let countdown2 = Countdown(
                name: "Meeting",
                targetDate: calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                includeTime: true
            )
            countdown2.id = UUID()
            context.insert(countdown2)

            // Add occasions
            let occasion1 = Occasion(
                title: "Birthday",
                occasionType: .birthday,
                personName: "Alice",
                month: calendar.component(.month, from: calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()),
                day: 15,
                startYear: 1990,
                iconName: "gift",
                category: category
            )
            context.insert(occasion1)

            let occasion2 = Occasion(
                title: "Anniversary",
                occasionType: .anniversary,
                personName: nil,
                month: calendar.component(.month, from: Date()),
                day: calendar.component(.day, from: Date()),
                startYear: 2020,
                iconName: "heart",
                category: nil
            )
            context.insert(occasion2)
        }

        try? context.save()
    }

    static func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func assignMissingCountdownIDsIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Countdown>()
        let countdowns = try context.fetch(descriptor)
        var didUpdate = false

        for countdown in countdowns where countdown.id == nil {
            countdown.id = UUID()
            didUpdate = true
        }

        if didUpdate {
            try context.save()
        }
    }

    static func migrateExistingOccasionsIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Countdown>(
            predicate: #Predicate { $0.eventTypeRawValue != nil }
        )
        let countdownsWithEventType = try context.fetch(descriptor)

        guard !countdownsWithEventType.isEmpty else { return }

        let calendar = Calendar.current

        for countdown in countdownsWithEventType {
            guard let eventTypeRaw = countdown.eventTypeRawValue,
                  let occasionType = OccasionType(rawValue: eventTypeRaw) else { continue }

            let initialDate = countdown.initialTargetDate ?? countdown.targetDate
            let month = calendar.component(.month, from: initialDate)
            let dayOfMonth = calendar.component(.day, from: initialDate)
            let startYear = calendar.component(.year, from: initialDate)

            let occasion = Occasion(
                title: countdown.name,
                occasionType: occasionType,
                personName: countdown.name,
                month: month,
                day: dayOfMonth,
                startYear: startYear,
                iconName: countdown.iconName,
                category: countdown.category
            )

            context.insert(occasion)
            context.delete(countdown)
        }

        try context.save()
    }
}

enum SharedContainerError: LocalizedError {
    case missingEntitlement

    var errorDescription: String? {
        switch self {
        case .missingEntitlement:
            return "Unable to access shared container. Ensure the app group entitlement is configured."
        }
    }
}
