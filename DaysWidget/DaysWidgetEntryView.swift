//
//  DaysWidgetEntryView.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import WidgetKit

struct UpcomingDaysWidgetEntryView: View {
    var entry: DayEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                UpcomingMediumView(entry: entry)
            default:
                UpcomingSmallView(entry: entry)
            }
        }
        .containerBackground(.thinMaterial, for: .widget)
    }
}

struct PinnedDayWidgetEntryView: View {
    var entry: DayEntry

    var body: some View {
        PinnedSmallView(entry: entry)
            .containerBackground(.thinMaterial, for: .widget)
    }
}

// MARK: - Shared UI

private struct IconCircle: View {
    let iconName: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.secondary.opacity(0.1))
                .frame(width: size, height: size)
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: size * 0.22, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let urlString: String

    var body: some View {
        Link(destination: URL(string: urlString)!) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
        }
    }
}

private struct MissingPinnedStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "pin.slash")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Pinned event unavailable")
                .font(.headline.weight(.semibold))
            Text("Open the app to reconfigure this widget.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
    }
}

// MARK: - Automatic Small

private struct UpcomingSmallView: View {
    let entry: DayEntry

    private var snapshot: DaySnapshot? {
        WidgetSelection.nearestItem(from: entry.snapshots, now: entry.date)
    }

    var body: some View {
        Group {
            if entry.snapshots.isEmpty {
                EmptyStateView(
                    title: "Add an event",
                    subtitle: "Tap to create your first countdown or occasion.",
                    urlString: "days://add"
                )
            } else if let snapshot {
                Link(destination: deepLinkURL(for: snapshot)) {
                    SmallContentView(snapshot: snapshot)
                        .contentShape(Rectangle())
                }
            }
        }
    }
}

private struct SmallContentView: View {
    let snapshot: DaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                IconCircle(iconName: snapshot.iconName, size: 32)
                Text(snapshot.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 8)

            Text(CountdownHelper.formatCountdown(to: snapshot.targetDate, includeTime: snapshot.includeTime))
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .monospacedDigit()

            Text(snapshot.targetDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }
}

// MARK: - Automatic Medium

private struct UpcomingMediumView: View {
    let entry: DayEntry

    private var snapshots: [DaySnapshot] {
        WidgetSelection.upcomingItems(from: entry.snapshots, now: entry.date, limit: 2)
    }

    var body: some View {
        Group {
            if entry.snapshots.isEmpty {
                EmptyStateView(
                    title: "No upcoming events",
                    subtitle: "Tap to add a countdown or occasion.",
                    urlString: "days://add"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                        Link(destination: deepLinkURL(for: snapshot)) {
                            MediumRowView(snapshot: snapshot)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        if index < snapshots.count - 1 {
                            Divider()
                                .overlay(.secondary.opacity(0.25))
                                .padding(.horizontal, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
    }
}

private struct MediumRowView: View {
    let snapshot: DaySnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IconCircle(iconName: snapshot.iconName, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(snapshot.targetDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(CountdownHelper.formatCountdown(to: snapshot.targetDate, includeTime: snapshot.includeTime))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Pinned Small

private struct PinnedSmallView: View {
    let entry: DayEntry

    private var snapshot: DaySnapshot? {
        WidgetSelection.pinnedItem(from: entry.snapshots, selectedID: entry.selectedDayID)
    }

    var body: some View {
        Group {
            if entry.snapshots.isEmpty {
                EmptyStateView(
                    title: "Add an event",
                    subtitle: "Tap to create something to pin.",
                    urlString: "days://add"
                )
            } else if let snapshot {
                Link(destination: deepLinkURL(for: snapshot)) {
                    SmallContentView(snapshot: snapshot)
                        .contentShape(Rectangle())
                }
            } else {
                MissingPinnedStateView()
            }
        }
    }
}

private func deepLinkURL(for day: DaySnapshot) -> URL {
    let path = day.kind == .occasion ? "occasion" : "countdown"
    return URL(string: "days://\(path)/\(day.id.uuidString)")!
}

// MARK: - Previews

private let previewMixedEntry = DayEntry(
    date: .now,
    snapshots: [
        DaySnapshot(id: UUID(), kind: .countdown, name: "Birthday", targetDate: .now.addingTimeInterval(86400 * 5), includeTime: false, iconName: "birthday.cake"),
        DaySnapshot(id: UUID(), kind: .occasion, name: "Anniversary", targetDate: .now.addingTimeInterval(86400 * 14), includeTime: false, iconName: "heart"),
        DaySnapshot(id: UUID(), kind: .occasion, name: "Anniversary", targetDate: .now.addingTimeInterval(86400 * 14), includeTime: false, iconName: "heart")
    ]
)

private let emptyEntry = DayEntry(date: .now, snapshots: [])
private let pinnedMissingEntry = DayEntry(date: .now, snapshots: previewMixedEntry.snapshots, selectedDayID: UUID())

#Preview("Upcoming Small", as: .systemSmall, widget: { UpcomingDaysWidget() }, timeline: { previewMixedEntry })
#Preview("Upcoming Medium", as: .systemMedium, widget: { UpcomingDaysWidget() }, timeline: { previewMixedEntry })
#Preview("Upcoming Empty", as: .systemSmall, widget: { UpcomingDaysWidget() }, timeline: { emptyEntry })
#Preview("Pinned Small", as: .systemSmall, widget: { PinnedDayWidget() }, timeline: { DayEntry(date: .now, snapshots: previewMixedEntry.snapshots, selectedDayID: previewMixedEntry.snapshots[0].id) })
#Preview("Pinned Missing", as: .systemSmall, widget: { PinnedDayWidget() }, timeline: { pinnedMissingEntry })
