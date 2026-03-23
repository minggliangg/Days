//
//  LiveCountdownView.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import Combine

struct LiveCountdownView: View {
    let targetDate: Date
    let includeTime: Bool

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var countdownText: String {
        CountdownHelper.formatCountdown(to: targetDate, includeTime: includeTime)
    }

    private var isPast: Bool {
        targetDate < now
    }

    var body: some View {
        Text(countdownText)
            .onReceive(timer) { _ in
                now = Date()
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        LiveCountdownView(targetDate: Date().addingTimeInterval(3600), includeTime: true)
        LiveCountdownView(targetDate: Date().addingTimeInterval(86400 * 5), includeTime: false)
        LiveCountdownView(targetDate: Date().addingTimeInterval(-3600), includeTime: true)
    }
    .padding()
}
