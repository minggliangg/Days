//
//  OccasionType.swift
//  Days
//
//  Created by Ming Liang Khong on 24/3/26.
//

import Foundation

enum OccasionType: String, Codable, CaseIterable {
    case birthday
    case anniversary

    var displayName: String {
        switch self {
        case .birthday:    return "Birthday"
        case .anniversary: return "Anniversary"
        }
    }
}
