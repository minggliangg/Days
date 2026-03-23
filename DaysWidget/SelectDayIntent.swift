//
//  SelectDayIntent.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import AppIntents
import SwiftData
import Foundation

struct SelectDayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Countdown to Display"
    static var description: IntentDescription = "Choose which countdown to show on the widget. Leave empty to show the next upcoming event."

    @Parameter(title: "Specific Countdown", description: "Leave empty to show the next upcoming event")
    var selectedDay: DayEntity?
}

struct DayEntity: AppEntity {
    var id: UUID
    var name: String
    var targetDate: Date
    var iconName: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Countdown"
    static var defaultQuery = DayEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct DayEntityQuery: EntityQuery {
    func entities(for identifiers: [DayEntity.ID]) async throws -> [DayEntity] {
        let allCountdowns = try fetchAllCountdowns()
        return allCountdowns.filter { identifiers.contains($0.id) }.map { DayEntity(id: $0.id, name: $0.name, targetDate: $0.targetDate, iconName: $0.iconName) }
    }

    func suggestedEntities() async throws -> [DayEntity] {
        let allCountdowns = try fetchAllCountdowns()
        return allCountdowns.map { DayEntity(id: $0.id, name: $0.name, targetDate: $0.targetDate, iconName: $0.iconName) }
    }

    private func fetchAllCountdowns() throws -> [DaySnapshot] {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)
        try SharedModelContainer.assignMissingCountdownIDsIfNeeded(in: context)
        let descriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.targetDate)])
        let countdowns = try context.fetch(descriptor)
        return countdowns.compactMap { countdown in
            guard let id = countdown.id else { return nil }
            return DaySnapshot(id: id, kind: .countdown, name: countdown.name, targetDate: countdown.targetDate, includeTime: countdown.includeTime, iconName: countdown.iconName)
        }
    }
}
