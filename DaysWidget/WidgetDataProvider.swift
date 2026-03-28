//
//  WidgetDataProvider.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 28/3/26.
//

import Foundation
import SwiftData

enum WidgetDataProvider {
    static func loadSnapshots() throws -> [DaySnapshot] {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)
        try SharedModelContainer.assignMissingCountdownIDsIfNeeded(in: context)

        let countdownDescriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.targetDate)])
        let countdowns = try context.fetch(countdownDescriptor).compactMap { countdown -> DaySnapshot? in
            guard let id = countdown.id else { return nil }
            return DaySnapshot(
                id: id,
                kind: .countdown,
                name: countdown.name,
                targetDate: countdown.targetDate,
                includeTime: countdown.includeTime,
                iconName: countdown.iconName
            )
        }

        let occasionDescriptor = FetchDescriptor<Occasion>()
        let occasions = try context.fetch(occasionDescriptor).map { occasion in
            DaySnapshot(
                id: occasion.id,
                kind: .occasion,
                name: occasion.title,
                targetDate: occasion.nextOccurrenceDate,
                includeTime: false,
                iconName: occasion.iconName
            )
        }

        return (countdowns + occasions).sorted { $0.targetDate < $1.targetDate }
    }
}
