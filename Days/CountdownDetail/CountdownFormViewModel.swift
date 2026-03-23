//
//  CountdownFormViewModel.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class CountdownFormViewModel {
    private let modelContext: ModelContext
    private let countdown: Countdown?
    private let navigateToDetailOnSave: Bool
    private weak var navigationViewModel: HomeViewModel?

    var name: String
    var targetDate: Date
    var includeTime: Bool
    var selectedCategory: Category?
    var isRecurring: Bool
    var recurringIntervalType: RecurringIntervalType
    var recurringCustomDays: Int
    var occasionType: OccasionType?
    var iconName: String?

    var isValid: Bool {
        !name.isEmpty
    }

    var isEditing: Bool {
        countdown != nil
    }

    var showEventTypePicker: Bool { isRecurring && recurringIntervalType == .annually }

    init(
        modelContext: ModelContext,
        countdown: Countdown?,
        navigationViewModel: HomeViewModel,
        navigateToDetailOnSave: Bool
    ) {
        self.modelContext = modelContext
        self.countdown = countdown
        self.navigationViewModel = navigationViewModel
        self.navigateToDetailOnSave = navigateToDetailOnSave

        if let countdown = countdown {
            self.name = countdown.name
            self.targetDate = countdown.targetDate
            self.includeTime = countdown.includeTime
            self.selectedCategory = countdown.category
            self.isRecurring = countdown.isRecurring
            self.recurringIntervalType = countdown.intervalType ?? .monthly
            self.recurringCustomDays = countdown.recurringCustomDays ?? 30
            self.occasionType = countdown.occasionType
            self.iconName = countdown.iconName
        } else {
            self.name = ""
            self.targetDate = Date()
            self.includeTime = false
            self.selectedCategory = nil
            self.isRecurring = false
            self.recurringIntervalType = .monthly
            self.recurringCustomDays = 30
            self.occasionType = nil
            self.iconName = nil
        }
    }

    func selectIcon(_ name: String?) {
        iconName = name
    }

    func save() {
        guard isValid else { return }

        if let countdown = countdown {
            countdown.name = name
            countdown.targetDate = targetDate
            countdown.includeTime = includeTime
            countdown.category = selectedCategory
            countdown.isRecurring = isRecurring
            countdown.intervalType = isRecurring ? recurringIntervalType : nil
            countdown.recurringCustomDays = recurringIntervalType == .custom ? recurringCustomDays : nil
            countdown.occasionType = showEventTypePicker ? occasionType : nil
            countdown.iconName = iconName

            if isRecurring && countdown.initialTargetDate == nil {
                countdown.initialTargetDate = targetDate
            } else if !isRecurring {
                countdown.initialTargetDate = nil
            }

            if navigateToDetailOnSave {
                navigationViewModel?.popAndNavigateToDetail(countdown)
            } else {
                navigationViewModel?.pop()
            }
        } else {
            let newCountdown = Countdown(name: name, targetDate: targetDate, includeTime: includeTime)
            newCountdown.category = selectedCategory
            newCountdown.isRecurring = isRecurring
            newCountdown.intervalType = isRecurring ? recurringIntervalType : nil
            newCountdown.recurringCustomDays = recurringIntervalType == .custom ? recurringCustomDays : nil
            newCountdown.occasionType = showEventTypePicker ? occasionType : nil
            newCountdown.iconName = iconName
            if isRecurring {
                newCountdown.initialTargetDate = targetDate
            }
            modelContext.insert(newCountdown)
            navigationViewModel?.pop()
        }
        RecurringAdvancer.advanceIfNeeded(in: modelContext)
        SharedModelContainer.refreshWidgets()
    }
}
