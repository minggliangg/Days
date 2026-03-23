//
//  DaysWidget.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import SwiftUI
import AppIntents

struct DaysWidget: Widget {
    let kind: String = "DaysWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectDayIntent.self, provider: DaysProvider()) { entry in
            DaysWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Days Countdown")
        .description("Shows your upcoming countdowns.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

#Preview(as: .systemSmall) {
    DaysWidget()
} timeline: {
    DayEntry(
        date: .now,
        upcomingDays: [
            DaySnapshot(id: UUID(), kind: .countdown, name: "Birthday", targetDate: .now.addingTimeInterval(86400 * 5), includeTime: false, iconName: "birthday.cake"),
            DaySnapshot(id: UUID(), kind: .countdown, name: "Holiday", targetDate: .now.addingTimeInterval(86400 * 14), includeTime: false, iconName: "airplane")
        ]
    )
}

#Preview(as: .systemMedium) {
    DaysWidget()
} timeline: {
    DayEntry(
        date: .now,
        upcomingDays: [
            DaySnapshot(id: UUID(), kind: .countdown, name: "Birthday", targetDate: .now.addingTimeInterval(86400 * 5), includeTime: false, iconName: "birthday.cake"),
            DaySnapshot(id: UUID(), kind: .countdown, name: "Holiday", targetDate: .now.addingTimeInterval(86400 * 14), includeTime: false, iconName: "airplane")
        ]
    )
}
