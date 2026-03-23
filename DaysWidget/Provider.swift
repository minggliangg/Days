//
//  Provider.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import SwiftData
import Foundation
import AppIntents

struct DaysProvider: AppIntentTimelineProvider {
    typealias Entry = DayEntry
    typealias Intent = SelectDayIntent

    func placeholder(in context: Context) -> DayEntry {
        DayEntry(
            date: .now,
            upcomingDays: [
                DaySnapshot(
                    id: UUID(),
                    kind: .countdown,
                    name: "Example Event",
                    targetDate: .now.addingTimeInterval(86400 * 7),
                    includeTime: false,
                    iconName: nil
                )
            ]
        )
    }

    func snapshot(for configuration: SelectDayIntent, in context: Context) async -> DayEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectDayIntent, in context: Context) async -> Timeline<DayEntry> {
        let entry = await fetchEntry(for: configuration)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func fetchEntry(for configuration: SelectDayIntent) async -> DayEntry {
        do {
            let container = try SharedModelContainer.makeContainer()
            let context = ModelContext(container)
            try SharedModelContainer.assignMissingCountdownIDsIfNeeded(in: context)

            // Fetch Countdowns
            let countdownDescriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.targetDate)])
            let countdowns = try context.fetch(countdownDescriptor)
            var snapshots = countdowns.compactMap { countdown -> DaySnapshot? in
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

            // Fetch Occasions
            let occasionDescriptor = FetchDescriptor<Occasion>()
            let occasions = try context.fetch(occasionDescriptor)
            let occasionSnapshots = occasions.map { occasion -> DaySnapshot in
                DaySnapshot(
                    id: occasion.id,
                    kind: .occasion,
                    name: occasion.title,
                    targetDate: occasion.nextOccurrenceDate,
                    includeTime: false,
                    iconName: occasion.iconName
                )
            }

            // Merge and sort by target date
            snapshots.append(contentsOf: occasionSnapshots)
            snapshots.sort { $0.targetDate < $1.targetDate }

            let selectedDayID = configuration.selectedDay?.id
            return DayEntry(date: .now, upcomingDays: snapshots, selectedDayID: selectedDayID)
        } catch {
            return DayEntry(date: .now, upcomingDays: [], selectedDayID: nil)
        }
    }
}
