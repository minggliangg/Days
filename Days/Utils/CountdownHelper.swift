//
//  CountdownHelper.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation

struct CountdownHelper {
    static func timeRemaining(from now: Date, to target: Date, includeTime: Bool = true) -> (components: DateComponents, isPast: Bool) {
        let calendar = Calendar.current

        let effectiveNow: Date
        let effectiveTarget: Date
        if includeTime {
            effectiveNow = now
            effectiveTarget = target
        } else {
            effectiveNow = calendar.startOfDay(for: now)
            effectiveTarget = calendar.startOfDay(for: target)
        }

        let isPast = effectiveTarget < effectiveNow

        let components: DateComponents
        if isPast {
            components = calendar.dateComponents([.day, .hour, .minute, .second], from: effectiveTarget, to: effectiveNow)
        } else {
            components = calendar.dateComponents([.day, .hour, .minute, .second], from: effectiveNow, to: effectiveTarget)
        }

        return (components, isPast)
    }

    static func formatSmart(_ components: DateComponents, isPast: Bool, includeTime: Bool = true) -> String {
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0

        let prefix = isPast ? "" : ""
        let suffix = isPast ? " ago" : ""

        if !includeTime {
            return "\(prefix)\(days) day\(days == 1 ? "" : "s")\(suffix)"
        }

        if days > 30 {
            return "\(prefix)\(days) days\(suffix)"
        } else if days >= 1 {
            if hours > 0 {
                return "\(prefix)\(days) day\(days == 1 ? "" : "s") \(hours) hr\(suffix)"
            }
            return "\(prefix)\(days) day\(days == 1 ? "" : "s")\(suffix)"
        } else if hours >= 1 {
            if minutes > 0 {
                return "\(prefix)\(hours) hr \(minutes) min\(suffix)"
            }
            return "\(prefix)\(hours) hr\(suffix)"
        } else if minutes >= 1 {
            return "\(prefix)\(minutes) min \(seconds) sec\(suffix)"
        } else {
            return "\(prefix)\(seconds) sec\(suffix)"
        }
    }

    static func formatCountdown(to targetDate: Date, includeTime: Bool = true) -> String {
        let (components, isPast) = timeRemaining(from: Date(), to: targetDate, includeTime: includeTime)
        return formatSmart(components, isPast: isPast, includeTime: includeTime)
    }
}
