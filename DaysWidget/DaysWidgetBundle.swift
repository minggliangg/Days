//
//  DaysWidgetBundle.swift
//  DaysWidget
//
//  Created by Ming Liang Khong on 23/3/26.
//

import WidgetKit
import SwiftUI

@main
struct DaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        UpcomingDaysWidget()
        PinnedDayWidget()
    }
}
