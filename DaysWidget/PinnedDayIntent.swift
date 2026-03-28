//
//  PinnedDayIntent.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 28/3/26.
//

import AppIntents
import SwiftData
import Foundation

struct PinnedEventIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Pin an Event"
    static var description: IntentDescription = "Choose one event to pin on the widget."

    @Parameter(title: "Pinned Event", description: "Choose a countdown or occasion to pin")
    var pinnedEvent: DayEntity?
}

struct DayEntity: AppEntity {
    var id: UUID
    var kind: DaySnapshot.Kind
    var name: String
    var targetDate: Date
    var iconName: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = DayEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        let kindLabel = kind == .occasion ? "Occasion" : "Countdown"
        return DisplayRepresentation(title: "\(name)", subtitle: "\(kindLabel)")
    }
}

struct DayEntityQuery: EntityQuery {
    func entities(for identifiers: [DayEntity.ID]) async throws -> [DayEntity] {
        let allEntities = try fetchAllEntities()
        return allEntities.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DayEntity] {
        try fetchAllEntities()
    }

    private func fetchAllEntities() throws -> [DayEntity] {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)
        try SharedModelContainer.assignMissingCountdownIDsIfNeeded(in: context)

        let countdownDescriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.targetDate)])
        let countdowns = try context.fetch(countdownDescriptor).compactMap { countdown -> DayEntity? in
            guard let id = countdown.id else { return nil }
            return DayEntity(
                id: id,
                kind: .countdown,
                name: countdown.name,
                targetDate: countdown.targetDate,
                iconName: countdown.iconName
            )
        }

        let occasionDescriptor = FetchDescriptor<Occasion>()
        let occasions = try context.fetch(occasionDescriptor).map { occasion in
            DayEntity(
                id: occasion.id,
                kind: .occasion,
                name: occasion.title,
                targetDate: occasion.nextOccurrenceDate,
                iconName: occasion.iconName
            )
        }

        return (countdowns + occasions).sorted { $0.targetDate < $1.targetDate }
    }
}
