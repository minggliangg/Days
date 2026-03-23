//
//  RecurringAdvancer.swift
//  Days
//

import Foundation
import SwiftData

enum RecurringAdvancer {
    static func advanceIfNeeded(in context: ModelContext) {
        let now = Date()
        let calendar = Calendar.current

        let descriptor = FetchDescriptor<Countdown>(
            predicate: #Predicate { $0.isRecurring && $0.targetDate < now }
        )

        guard let countdowns = try? context.fetch(descriptor) else { return }

        for countdown in countdowns {
            guard countdown.intervalType != nil else { continue }

            while countdown.targetDate < now {
                advanceDate(countdown, calendar: calendar)
            }
        }

        if !countdowns.isEmpty {
            try? context.save()
            SharedModelContainer.refreshWidgets()
        }
    }

    private static func advanceDate(_ countdown: Countdown, calendar: Calendar) {
        guard let intervalType = countdown.intervalType else { return }

        let newDate: Date?
        switch intervalType {
        case .daily:
            newDate = calendar.date(byAdding: .day, value: 1, to: countdown.targetDate)
        case .weekly:
            newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: countdown.targetDate)
        case .monthly:
            newDate = calendar.date(byAdding: .month, value: 1, to: countdown.targetDate)
        case .annually:
            newDate = calendar.date(byAdding: .year, value: 1, to: countdown.targetDate)
        case .custom:
            let days = max(1, countdown.recurringCustomDays ?? 30)
            newDate = calendar.date(byAdding: .day, value: days, to: countdown.targetDate)
        }

        if let newDate = newDate {
            countdown.targetDate = newDate
        }
    }
}
