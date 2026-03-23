//
//  CategoryManagerViewModel.swift
//  Days
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class CategoryManagerViewModel {
    private let modelContext: ModelContext

    var categories: [Category] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchCategories()
    }

    func fetchCategories() {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    func createCategory(name: String, colorHex: String) -> Category {
        let maxSortOrder = categories.map(\.sortOrder).max() ?? -1
        let category = Category(name: name, colorHex: colorHex, sortOrder: maxSortOrder + 1)
        modelContext.insert(category)
        fetchCategories()
        return category
    }

    func renameCategory(_ category: Category, newName: String) {
        category.name = newName
    }

    func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        fetchCategories()
    }

    func moveCategory(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }

        fetchCategories()
    }

    func countdownCountForCategory(_ category: Category) -> Int {
        category.countdowns.count
    }
}
