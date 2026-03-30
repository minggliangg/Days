//
//  DaysWidget.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import SwiftUI
import AppIntents

struct UpcomingDaysWidget: Widget {
    let kind: String = "UpcomingDaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingDaysProvider()) { entry in
            UpcomingDaysWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Days")
        .description("Shows your upcoming events at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedDayWidget: Widget {
    let kind: String = "PinnedDayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PinnedEventIntent.self, provider: PinnedDayProvider()) { entry in
            PinnedDayWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Pinned Event")
        .description("Shows one selected countdown or occasion.")
        .supportedFamilies([.systemSmall])
    }
}

struct PinnedDayProvider: AppIntentTimelineProvider {
    typealias Entry = DayEntry
    typealias Intent = PinnedEventIntent

    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: .now, snapshots: [
            DaySnapshot(id: UUID(), kind: .occasion, name: "Anniversary", targetDate: .now.addingTimeInterval(86400 * 3), includeTime: false, iconName: "heart", imagePath: nil)
        ])
    }

    func snapshot(for configuration: PinnedEventIntent, in context: Context) async -> DayEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: PinnedEventIntent, in context: Context) async -> Timeline<DayEntry> {
        let entry = await fetchEntry(for: configuration)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func fetchEntry(for configuration: PinnedEventIntent) async -> DayEntry {
        do {
            let snapshots = try WidgetDataProvider.loadSnapshots()
            let selectedID = configuration.pinnedEvent?.id
            return DayEntry(date: .now, snapshots: snapshots, selectedDayID: selectedID)
        } catch {
            return DayEntry(date: .now, snapshots: [], selectedDayID: nil)
        }
    }
}
