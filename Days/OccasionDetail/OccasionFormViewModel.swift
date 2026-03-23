//
//  OccasionFormViewModel.swift
//  Days
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class OccasionFormViewModel {
    private let modelContext: ModelContext
    private let occasion: Occasion?
    private weak var navigationViewModel: HomeViewModel?

    var title: String
    var occasionType: OccasionType
    var personName: String?
    var selectedDate: Date
    var iterationMode: IterationMode
    var manualIteration: Int
    var iconName: String?
    var selectedCategory: Category?

    enum IterationMode {
        case derived
        case manual
    }

    var isValid: Bool {
        !title.isEmpty
    }

    var isEditing: Bool {
        occasion != nil
    }

    init(
        modelContext: ModelContext,
        occasion: Occasion?,
        navigationViewModel: HomeViewModel
    ) {
        self.modelContext = modelContext
        self.occasion = occasion
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
            self.iconName = occasion.iconName
            self.selectedCategory = occasion.category
        } else {
            self.title = ""
            self.occasionType = .birthday
            self.personName = nil
            self.selectedDate = Date()
            self.iterationMode = .derived
            self.manualIteration = 1
            self.iconName = nil
            self.selectedCategory = nil
        }
    }

    func selectIcon(_ name: String?) {
        iconName = name
    }

    func save() {
        guard isValid else { return }

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

        if let occasion = occasion {
            occasion.title = title
            occasion.occasionType = occasionType
            occasion.personName = personName
            occasion.month = month
            occasion.day = day
            occasion.startYear = startYear
            occasion.iconName = iconName
            occasion.category = selectedCategory
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
            modelContext.insert(newOccasion)
            navigationViewModel?.pop()
        }
        SharedModelContainer.refreshWidgets()
    }
}
