//
//  RecurringIntervalType.swift
//  Days
//

import Foundation

enum RecurringIntervalType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case annually
    case custom

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annually: return "Annually"
        case .custom: return "Custom"
        }
    }
}
