//
//  Provider.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import Foundation
import AppIntents

struct UpcomingDaysProvider: TimelineProvider {
    typealias Entry = DayEntry

    func placeholder(in context: Context) -> DayEntry {
        DayEntry(
            date: .now,
            snapshots: [
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

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        Task {
            completion(await fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func fetchEntry() async -> DayEntry {
        do {
            let snapshots = try WidgetDataProvider.loadSnapshots()
            return DayEntry(date: .now, snapshots: snapshots)
        } catch {
            return DayEntry(date: .now, snapshots: [], selectedDayID: nil)
        }
    }
}
