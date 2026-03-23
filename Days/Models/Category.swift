//
//  Category.swift
//  Days
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Countdown.category)
    var countdowns: [Countdown] = []

    @Relationship(deleteRule: .nullify)
    var occasions: [Occasion] = []

    init(name: String, colorHex: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
