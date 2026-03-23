//
//  NavigationDestination.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import SwiftData

enum Destination: Hashable {
    case detail(countdownID: PersistentIdentifier)
    case edit(countdownID: PersistentIdentifier)
    case add
    case addOccasion
    case occasionDetail(occasionID: PersistentIdentifier)
    case occasionEdit(occasionID: PersistentIdentifier)
}
