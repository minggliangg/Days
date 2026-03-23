//
//  HomeViewModel.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import Foundation
import SwiftData
import SwiftUI

enum HomeFilter: Equatable {
    case all
    case occasions
    case category(Category)
}

@Observable
final class HomeViewModel {
    private let modelContext: ModelContext

    var navigationPath: [Destination] = []
    var selectedFilter: HomeFilter = .all

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func deleteCountdown(_ countdown: Countdown) {
        modelContext.delete(countdown)
        SharedModelContainer.refreshWidgets()
    }

    func deleteOccasion(_ occasion: Occasion) {
        modelContext.delete(occasion)
        SharedModelContainer.refreshWidgets()
    }

    func navigateToDetail(_ countdown: Countdown) {
        navigationPath.append(Destination.detail(countdownID: countdown.persistentModelID))
    }

    func navigateToOccasionDetail(_ occasion: Occasion) {
        navigationPath.append(Destination.occasionDetail(occasionID: occasion.persistentModelID))
    }

    func navigateToEdit(_ countdown: Countdown) {
        navigationPath.append(Destination.edit(countdownID: countdown.persistentModelID))
    }

    func navigateToOccasionEdit(_ occasion: Occasion) {
        navigationPath.append(Destination.occasionEdit(occasionID: occasion.persistentModelID))
    }

    func navigateToAdd() {
        navigationPath.append(Destination.add)
    }

    func navigateToAddOccasion() {
        navigationPath.append(Destination.addOccasion)
    }

    func fetchCountdown(by id: PersistentIdentifier) -> Countdown? {
        modelContext.model(for: id) as? Countdown
    }

    func fetchOccasion(by id: PersistentIdentifier) -> Occasion? {
        modelContext.model(for: id) as? Occasion
    }

    func fetchCountdown(by id: UUID) throws -> Countdown? {
        let idToMatch: UUID? = id
        let descriptor = FetchDescriptor<Countdown>(predicate: #Predicate { $0.id == idToMatch })
        return try modelContext.fetch(descriptor).first
    }

    func fetchOccasion(by id: UUID) throws -> Occasion? {
        let descriptor = FetchDescriptor<Occasion>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func popAndNavigateToDetail(_ countdown: Countdown) {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }

        let detailDestination = Destination.detail(countdownID: countdown.persistentModelID)
        if navigationPath.last != detailDestination {
            navigationPath.append(detailDestination)
        }
    }

    func popAndNavigateToOccasionDetail(_ occasion: Occasion) {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }

        let detailDestination = Destination.occasionDetail(occasionID: occasion.persistentModelID)
        if navigationPath.last != detailDestination {
            navigationPath.append(detailDestination)
        }
    }

    func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .add:
            navigationPath = []
            navigationPath.append(Destination.add)
        case .countdown(let id):
            if let countdown = try? fetchCountdown(by: id) {
                navigationPath = []
                navigateToDetail(countdown)
            }
        case .occasion(let id):
            if let occasion = try? fetchOccasion(by: id) {
                navigationPath = []
                navigateToOccasionDetail(occasion)
            }
        }

        NotificationCenter.default.post(name: .clearDeepLink, object: nil)
    }
}
