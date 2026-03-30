//
//  CountdownFormViewModel.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

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
    var selectedImage: UIImage?
    var existingImagePath: String?
    var existingImage: UIImage?
    var imageRemoved: Bool = false

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
            self.existingImagePath = countdown.imagePath
            self.existingImage = ImageManager.loadImage(relativePath: countdown.imagePath)
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

    func selectImage(_ image: UIImage) {
        selectedImage = image
        existingImage = nil
        imageRemoved = false
    }

    func removeImage() {
        selectedImage = nil
        existingImage = nil
        imageRemoved = true
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

            if imageRemoved {
                if let id = countdown.id {
                    ImageManager.deleteImage(forEventID: id)
                }
                countdown.imagePath = nil
                imageRemoved = false
            } else if let selectedImage {
                let eventID = countdown.id ?? UUID()
                if let newPath = ImageManager.processAndSave(image: selectedImage, forEventID: eventID) {
                    if countdown.id == nil { countdown.id = eventID }
                    countdown.imagePath = newPath
                }
            }

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
            if let selectedImage {
                if let path = ImageManager.processAndSave(image: selectedImage, forEventID: newCountdown.id ?? UUID()) {
                    newCountdown.imagePath = path
                }
            }
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
