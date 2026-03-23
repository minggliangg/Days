//
//  AnyEntry.swift
//  Days
//

import Foundation
import SwiftData

enum AnyEntry: Identifiable {
    case countdown(Countdown)
    case occasion(Occasion)

    var id: PersistentIdentifier {
        switch self {
        case .countdown(let countdown):
            return countdown.persistentModelID
        case .occasion(let occasion):
            return occasion.persistentModelID
        }
    }

    var title: String {
        switch self {
        case .countdown(let countdown):
            return countdown.name
        case .occasion(let occasion):
            return occasion.title
        }
    }

    var iconName: String? {
        switch self {
        case .countdown(let countdown):
            return countdown.iconName
        case .occasion(let occasion):
            return occasion.iconName
        }
    }

    var category: Category? {
        switch self {
        case .countdown(let countdown):
            return countdown.category
        case .occasion(let occasion):
            return occasion.category
        }
    }

    var nextDate: Date {
        switch self {
        case .countdown(let countdown):
            return countdown.targetDate
        case .occasion(let occasion):
            return occasion.nextOccurrenceDate
        }
    }

    var includeTime: Bool {
        switch self {
        case .countdown(let countdown):
            return countdown.includeTime
        case .occasion:
            return false
        }
    }

    var isPast: Bool {
        let date = nextDate
        return date < Date() && !Calendar.current.isDateInToday(date)
    }

    var isOccasion: Bool {
        if case .occasion = self { return true }
        return false
    }
}
