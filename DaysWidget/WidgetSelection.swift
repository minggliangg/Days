//
//  WidgetSelection.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 28/3/26.
//

import Foundation

enum WidgetSelection {
    static func upcomingItems(from snapshots: [DaySnapshot], now: Date = .now, limit: Int) -> [DaySnapshot] {
        guard !snapshots.isEmpty else { return [] }

        let sorted = snapshots.sorted { $0.targetDate < $1.targetDate }
        let upcoming = sorted.filter { $0.targetDate >= now }

        if !upcoming.isEmpty {
            return Array(upcoming.prefix(limit))
        }

        return Array(sorted.suffix(limit))
    }

    static func pinnedItem(from snapshots: [DaySnapshot], selectedID: UUID?) -> DaySnapshot? {
        guard let selectedID else { return nil }
        return snapshots.first { $0.id == selectedID }
    }

    static func nearestItem(from snapshots: [DaySnapshot], now: Date = .now) -> DaySnapshot? {
        upcomingItems(from: snapshots, now: now, limit: 1).first
    }
}
