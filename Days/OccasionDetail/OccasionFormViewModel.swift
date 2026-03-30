//
//  OccasionFormViewModel.swift
//  Days
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Observable
final class OccasionFormViewModel {
    private let modelContext: ModelContext
    private let editingOccasionID: PersistentIdentifier?
    private weak var navigationViewModel: HomeViewModel?

    var title: String
    var occasionType: OccasionType
    var personName: String?
    var selectedDate: Date
    var iterationMode: IterationMode
    var manualIteration: Int
    var manualIterationText: String
    var iconName: String?
    var selectedCategory: Category?
    var selectedImage: UIImage?
    var existingImagePath: String?
    var existingImage: UIImage?
    var imageRemoved: Bool = false

    enum IterationMode {
        case derived
        case manual
    }

    var isValid: Bool {
        !title.isEmpty
    }

    var isEditing: Bool {
        editingOccasionID != nil
    }

    init(
        modelContext: ModelContext,
        occasion: Occasion?,
        navigationViewModel: HomeViewModel
    ) {
        self.modelContext = modelContext
        self.editingOccasionID = occasion?.persistentModelID
        self.navigationViewModel = navigationViewModel

        if let occasion = occasion {
            self.title = occasion.title
            self.occasionType = occasion.occasionType
            self.personName = occasion.personName
            self.selectedDate = Calendar.current.date(
                from: DateComponents(
                    year: occasion.startYear,
                    month: occasion.month,
                    day: occasion.day
                )
            ) ?? occasion.nextOccurrenceDate
            self.iterationMode = .derived
            self.manualIteration = occasion.nextIteration
            self.manualIterationText = "\(occasion.nextIteration)"
            self.iconName = occasion.iconName
            self.selectedCategory = occasion.category
            self.existingImagePath = occasion.imagePath
            self.existingImage = ImageManager.loadImage(relativePath: occasion.imagePath)
        } else {
            self.title = ""
            self.occasionType = .birthday
            self.personName = nil
            self.selectedDate = Date()
            self.iterationMode = .derived
            self.manualIteration = 1
            self.manualIterationText = "1"
            self.iconName = nil
            self.selectedCategory = nil
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

    func updateManualIteration(from text: String) {
        if let value = Int(text), (1...200).contains(value) {
            manualIteration = value
            manualIterationText = text
        } else if text.isEmpty {
            manualIterationText = ""
        }
    }

    func commitManualIterationText() {
        if let value = Int(manualIterationText), (1...200).contains(value) {
            manualIteration = value
        }
        manualIterationText = "\(manualIteration)"
    }

    func save() {
        guard isValid else { return }

        commitManualIterationText()

        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedDate)
        let day = calendar.component(.day, from: selectedDate)

        let startYear: Int
        switch iterationMode {
        case .derived:
            startYear = calendar.component(.year, from: selectedDate)
        case .manual:
            let nextOccurrenceYear: Int
            let now = Date()
            let currentYear = calendar.component(.year, from: now)
            let comps = DateComponents(year: currentYear, month: month, day: day)

            if let date = calendar.date(from: comps), date >= now {
                nextOccurrenceYear = currentYear
            } else {
                nextOccurrenceYear = currentYear + 1
            }
            startYear = nextOccurrenceYear - manualIteration
        }

        if let editingOccasionID = editingOccasionID,
           let occasion = modelContext.model(for: editingOccasionID) as? Occasion {
            occasion.title = title
            occasion.occasionType = occasionType
            occasion.personName = personName
            occasion.month = month
            occasion.day = day
            occasion.startYear = startYear
            occasion.iconName = iconName
            occasion.category = selectedCategory

            if imageRemoved {
                ImageManager.deleteImage(forEventID: occasion.id)
                occasion.imagePath = nil
                imageRemoved = false
            } else if let selectedImage {
                if let newPath = ImageManager.processAndSave(image: selectedImage, forEventID: occasion.id) {
                    occasion.imagePath = newPath
                }
            }

            navigationViewModel?.popAndNavigateToOccasionDetail(occasion)
        } else {
            let newOccasion = Occasion(
                title: title,
                occasionType: occasionType,
                personName: personName,
                month: month,
                day: day,
                startYear: startYear,
                iconName: iconName,
                category: selectedCategory
            )
            if let selectedImage {
                if let path = ImageManager.processAndSave(image: selectedImage, forEventID: newOccasion.id) {
                    newOccasion.imagePath = path
                }
            }
            modelContext.insert(newOccasion)
            navigationViewModel?.pop()
        }
        SharedModelContainer.refreshWidgets()
    }
}
