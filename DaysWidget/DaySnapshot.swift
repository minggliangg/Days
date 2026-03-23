//
//  DaySnapshot.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import Foundation

struct DaySnapshot: Identifiable, Codable {
    enum Kind: String, Codable {
        case countdown
        case occasion
    }

    let id: UUID
    let kind: Kind
    let name: String
    let targetDate: Date
    let includeTime: Bool
    let iconName: String?
}

struct DayEntry: TimelineEntry {
    let date: Date
    let upcomingDays: [DaySnapshot]
    let selectedDayID: UUID?
    
    init(date: Date, upcomingDays: [DaySnapshot], selectedDayID: UUID? = nil) {
        self.date = date
        self.upcomingDays = upcomingDays
        self.selectedDayID = selectedDayID
    }
}
