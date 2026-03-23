//
//  DaysWidgetEntryView.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import WidgetKit

struct DaysWidgetEntryView: View {
    var entry: DaysProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .accessoryRectangular:
                LockScreenRectangularView(entry: entry)
            case .accessoryCircular:
                LockScreenCircularView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Small (.systemSmall)

struct SmallWidgetView: View {
    let entry: DayEntry
    private let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    private var displayDay: DaySnapshot? {
        if let selectedID = entry.selectedDayID {
            return entry.upcomingDays.first { $0.id == selectedID }
        }
        return entry.upcomingDays
            .filter { $0.targetDate >= entry.date }
            .min(by: { $0.targetDate < $1.targetDate })
            ?? entry.upcomingDays.last
    }

    private var hasNoEntries: Bool {
        entry.upcomingDays.isEmpty
    }

    var body: some View {
        Group {
            if hasNoEntries {
                emptyStateView
            } else if let day = displayDay {
                dayContentView(day)
            } else {
                noSelectedDayView
            }
        }
    }

    private var emptyStateView: some View {
        Link(destination: URL(string: "days://add")!) {
            VStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 42, weight: .light))
                Text("Add Event")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.46),
                        Color.white.opacity(0.26),
                        Color.white.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: cardShape
            )
            .overlay(
                cardShape.strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
            )
        }
        .padding()
        .containerBackground(for: .widget) {
            
        }
    }

    private func dayContentView(_ day: DaySnapshot) -> some View {
        Link(destination: deepLinkURL(for: day)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(day.name)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let iconName = day.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                Spacer(minLength: 22)
                Text(CountdownHelper.formatCountdown(to: day.targetDate, includeTime: day.includeTime))
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 22)
                Text(day.targetDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 23, weight: .regular, design: .default))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.46),
                        Color.white.opacity(0.26),
                        Color.white.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: cardShape
            )
            .overlay(
                cardShape.strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
    }

    private var noSelectedDayView: some View {
        VStack(spacing: 8) {
            Text("No day selected")
                .font(.subheadline.weight(.semibold))
            Text("Open the app to choose one")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium (.systemMedium)

struct MediumWidgetView: View {
    let entry: DayEntry
    private let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    private var nextTwo: [DaySnapshot] {
        Array(
            entry.upcomingDays
                .filter { $0.targetDate >= entry.date }
                .sorted { $0.targetDate < $1.targetDate }
                .prefix(2)
        )
    }

    var body: some View {
        Group {
            if nextTwo.isEmpty {
                emptyStateView
            } else {
                HStack(spacing: 8) {
                    ForEach(nextTwo) { day in
                        MediumEventCard(day: day)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        Link(destination: URL(string: "days://add")!) {
            VStack(spacing: 6) {
                Text("No upcoming events")
                    .font(.title2.weight(.bold))
                Text("Tap to add a countdown")
                    .font(.headline.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
        }
    }
}

struct MediumEventCard: View {
    let day: DaySnapshot
    private let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    var body: some View {
        Link(destination: deepLinkURL(for: day)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(day.name)
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let iconName = day.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                Spacer(minLength: 26)
                Text(CountdownHelper.formatCountdown(to: day.targetDate, includeTime: day.includeTime))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 26)
                Text(day.targetDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 21, weight: .regular, design: .default))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.46),
                        Color.white.opacity(0.26),
                        Color.white.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: cardShape
            )
            .overlay(
                cardShape.strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Lock Screen Rectangular (.accessoryRectangular)

struct LockScreenRectangularView: View {
    let entry: DayEntry

    private var next: DaySnapshot? {
        entry.upcomingDays
            .filter { $0.targetDate >= entry.date }
            .min(by: { $0.targetDate < $1.targetDate })
    }

    private func deepLinkURL(for day: DaySnapshot) -> URL {
        let path = day.kind == .occasion ? "occasion" : "countdown"
        return URL(string: "days://\(path)/\(day.id.uuidString)")!
    }

    var body: some View {
        if let day = next {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text(CountdownHelper.formatCountdown(to: day.targetDate, includeTime: day.includeTime))
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("No days")
                .font(.caption)
        }
    }
}

// MARK: - Lock Screen Circular (.accessoryCircular)

struct LockScreenCircularView: View {
    let entry: DayEntry

    private var next: DaySnapshot? {
        entry.upcomingDays
            .filter { $0.targetDate >= entry.date }
            .min(by: { $0.targetDate < $1.targetDate })
    }

    private var daysRemaining: Int? {
        guard let day = next else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: day.targetDate).day
    }

    var body: some View {
        if let days = daysRemaining {
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("days")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: "calendar")
        }
    }
}

// MARK: - Previews

private let previewEntry = DayEntry(
    date: .now,
    upcomingDays: [
        DaySnapshot(id: UUID(), kind: .countdown, name: "Birthday", targetDate: .now.addingTimeInterval(86400 * 5), includeTime: false, iconName: "birthday.cake"),
        DaySnapshot(id: UUID(), kind: .countdown, name: "Holiday", targetDate: .now.addingTimeInterval(86400 * 14), includeTime: false, iconName: "airplane")
    ]
)

private let emptyEntry = DayEntry(date: .now, upcomingDays: [])

#Preview("Small", as: .systemSmall, widget: { DaysWidget() }, timeline: { previewEntry })
#Preview("Small Empty", as: .systemSmall, widget: { DaysWidget() }, timeline: { emptyEntry })
#Preview("Medium", as: .systemMedium, widget: { DaysWidget() }, timeline: { previewEntry })
#Preview("Lock Screen Rectangular", as: .accessoryRectangular, widget: { DaysWidget() }, timeline: { previewEntry })
#Preview("Lock Screen Circular", as: .accessoryCircular, widget: { DaysWidget() }, timeline: { previewEntry })

private func deepLinkURL(for day: DaySnapshot) -> URL {
    let path = day.kind == .occasion ? "occasion" : "countdown"
    return URL(string: "days://\(path)/\(day.id.uuidString)")!
}
