//
//  Countdown.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import SwiftData

@Model
final class Countdown {
    var id: UUID?
    var name: String
    var targetDate: Date
    var includeTime: Bool
    var iconName: String?
    var category: Category?
    var isRecurring: Bool
    var recurringIntervalType: String?
    var recurringCustomDays: Int?
    var initialTargetDate: Date?
    var eventTypeRawValue: String?
    var imagePath: String?

    var occasionType: OccasionType? {
        get { eventTypeRawValue.flatMap(OccasionType.init(rawValue:)) }
        set { eventTypeRawValue = newValue?.rawValue }
    }

    var intervalType: RecurringIntervalType? {
        get {
            guard let rawValue = recurringIntervalType else { return nil }
            return RecurringIntervalType(rawValue: rawValue)
        }
        set {
            recurringIntervalType = newValue?.rawValue
        }
    }

    init(name: String, targetDate: Date, includeTime: Bool = false) {
        self.id = UUID()
        self.name = name
        self.targetDate = targetDate
        self.includeTime = includeTime
        self.iconName = nil
        self.isRecurring = false
    }
}
