//
//  Occasion.swift
//  Days
//

import Foundation
import SwiftData

@Model
final class Occasion {
    var id: UUID
    var title: String
    var occasionTypeRaw: String
    var personName: String?
    var month: Int
    var day: Int
    var startYear: Int
    var iconName: String?

    @Relationship(deleteRule: .nullify)
    var category: Category?

    var occasionType: OccasionType {
        get { OccasionType(rawValue: occasionTypeRaw) ?? .birthday }
        set { occasionTypeRaw = newValue.rawValue }
    }

    var nextOccurrenceDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let currentYear = calendar.component(.year, from: now)
        var comps = DateComponents(year: currentYear, month: month, day: day)

        if let date = calendar.date(from: comps), date >= startOfToday {
            return date
        }

        comps.year = currentYear + 1
        return calendar.date(from: comps)!
    }

    var nextIteration: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: nextOccurrenceDate) - startYear
    }

    init(
        title: String,
        occasionType: OccasionType,
        personName: String? = nil,
        month: Int,
        day: Int,
        startYear: Int,
        iconName: String? = nil,
        category: Category? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.occasionTypeRaw = occasionType.rawValue
        self.personName = personName
        self.month = month
        self.day = day
        self.startYear = startYear
        self.iconName = iconName
        self.category = category
    }
}
