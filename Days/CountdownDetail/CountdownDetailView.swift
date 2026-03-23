//
//  CountdownDetailView.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import SwiftData

struct CountdownDetailView: View {
    @Bindable var countdown: Countdown
    var viewModel: HomeViewModel

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = countdown.includeTime ? .short : .none
        return formatter.string(from: countdown.targetDate)
    }

    private var occurrenceCount: Int? {
        guard let initialDate = countdown.initialTargetDate else { return nil }
        guard let intervalType = countdown.intervalType else { return nil }

        return recurrenceOccurrenceCount(
            initialDate: initialDate,
            targetDate: countdown.targetDate,
            intervalType: intervalType,
            customDays: countdown.recurringCustomDays,
            occasionType: countdown.occasionType
        )
    }

    private var recurringText: String {
        guard let intervalType = countdown.intervalType else { return "Recurring" }
        switch intervalType {
        case .daily:
            return "Repeats daily"
        case .weekly:
            return "Repeats weekly"
        case .monthly:
            return "Repeats monthly"
        case .annually:
            return "Repeats annually"
        case .custom:
            let days = countdown.recurringCustomDays ?? 30
            return "Repeats every \(days) days"
        }
    }

    var body: some View {
        CountdownContent(
            iconName: countdown.iconName,
            targetDate: countdown.targetDate,
            includeTime: countdown.includeTime,
            displayDate: displayDate
        ) {
            if countdown.isRecurring {
                RecurringSummaryBadge(
                    recurringText: recurringText,
                    occurrenceDescription: occurrenceCount.map {
                        occurrenceLabel(for: $0, occasionType: countdown.occasionType)
                    }
                )
            }
        }
        .navigationTitle(countdown.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: navigateToEdit) {
                    Image(systemName: "pencil")
                }
            }
        }
    }

    private func navigateToEdit() {
        viewModel.navigateToEdit(countdown)
    }
}

private struct RecurringSummaryBadge: View {
    let recurringText: String
    let occurrenceDescription: String?

    var body: some View {
        CountdownDetailBadge {
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                Text(recurringText)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let occurrenceDescription {
                Text(occurrenceDescription)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct CountdownContent<SupplementaryContent: View>: View {
    let iconName: String?
    let targetDate: Date
    let includeTime: Bool
    let displayDate: String
    @ViewBuilder let supplementaryContent: SupplementaryContent

    init(
        iconName: String?,
        targetDate: Date,
        includeTime: Bool,
        displayDate: String,
        @ViewBuilder supplementaryContent: () -> SupplementaryContent
    ) {
        self.iconName = iconName
        self.targetDate = targetDate
        self.includeTime = includeTime
        self.displayDate = displayDate
        self.supplementaryContent = supplementaryContent()
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            LiveCountdownView(targetDate: targetDate, includeTime: includeTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Counting down to:")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(displayDate)
                .font(.title2)
                .multilineTextAlignment(.center)

            supplementaryContent

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct CountdownDetailBadge<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 8) {
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

private func ordinalString(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

func recurrenceOccurrenceCount(
    initialDate: Date,
    targetDate: Date,
    intervalType: RecurringIntervalType,
    customDays: Int?,
    occasionType: OccasionType?
) -> Int? {
    guard initialDate <= targetDate else { return nil }

    let calendar = Calendar.current
    let completedIntervals: Int

    switch intervalType {
    case .daily:
        completedIntervals = calendar.dateComponents([.day], from: initialDate, to: targetDate).day ?? 0
    case .weekly:
        completedIntervals = calendar.dateComponents([.weekOfYear], from: initialDate, to: targetDate).weekOfYear ?? 0
    case .monthly:
        completedIntervals = calendar.dateComponents([.month], from: initialDate, to: targetDate).month ?? 0
    case .annually:
        completedIntervals = calendar.dateComponents([.year], from: initialDate, to: targetDate).year ?? 0
        if occasionType == .birthday || occasionType == .anniversary {
            return completedIntervals
        }
    case .custom:
        let days = max(1, customDays ?? 30)
        completedIntervals = (calendar.dateComponents([.day], from: initialDate, to: targetDate).day ?? 0) / days
    }

    return max(1, completedIntervals + 1)
}

private func occurrenceLabel(for count: Int, occasionType: OccasionType?) -> String {
    let ordinal = ordinalString(for: count)
    switch occasionType {
    case .birthday:    return "\(ordinal) Birthday"
    case .anniversary: return "\(ordinal) Anniversary"
    case .none:        return "\(ordinal) occurrence"
    }
}
