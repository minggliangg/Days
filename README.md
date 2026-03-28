# Days

A countdown and occasion tracking app for iOS, built with SwiftUI and SwiftData.

## Features

- **Countdowns** — Track days until any future date, with optional time precision and custom icons
- **Occasions** — Remember annual events like birthdays and anniversaries, with automatic next-occurrence calculation
- **Recurring countdowns** — Set countdowns that repeat on daily, weekly, monthly, annual, or custom intervals
- **Categories** — Organize entries with color-coded categories and sort order
- **Home screen widgets** — Two widget types:
  - *Upcoming Events* (small & medium) — shows your next events at a glance
  - *Pinned Event* (small) — pick a specific countdown or occasion to display
- **Deep links** — URL scheme `days://` for quick actions:
  - `days://add` — create a new countdown
  - `days://countdown/<uuid>` — open a countdown
  - `days://occasion/<uuid>` — open an occasion
- **Live countdown view** — Real-time countdown display with seconds precision

## Tech Stack

- **SwiftUI** + **SwiftData** + **@Observable** (Swift 5.9 macro)
- **WidgetKit** with App Intents for configurable widgets
- **MVVM** architecture
- No UIKit, no Combine

## Requirements

- iOS 26.2+
- Xcode 26+
- Swift 5.0

## Getting Started

1. Clone the repository
2. Open `Days.xcodeproj` in Xcode
3. Build and run on the iOS Simulator or a physical device

```bash
# Build from the command line
xcodebuild -project Days.xcodeproj -scheme Days \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Testing

Tests use **Swift Testing** (not XCTest). Unit tests run against in-memory SwiftData containers.

```bash
# Run all tests
xcodebuild test -project Days.xcodeproj -scheme Days \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a specific test class
xcodebuild test -project Days.xcodeproj -scheme Days \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaysTests/HomeViewModelTests
```

## Project Structure

```
Days/
├── Days/                      # Main app target
│   ├── Models/                # SwiftData models
│   │   ├── Countdown.swift    # Countdown with date, icon, recurring interval
│   │   ├── Occasion.swift     # Annual event (birthday/anniversary)
│   │   ├── Category.swift     # Color-coded tag with sort order
│   │   ├── AnyEntry.swift     # Discriminated union for unified list display
│   │   ├── OccasionType.swift
│   │   └── RecurringIntervalType.swift
│   ├── Home/                  # Main screen
│   ├── CountdownDetail/       # Countdown CRUD views & form
│   ├── OccasionDetail/        # Occasion CRUD views & form
│   ├── Settings/              # Category management
│   ├── Components/            # Shared UI components
│   ├── Utils/                 # SharedModelContainer, RecurringAdvancer, helpers
│   ├── DaysApp.swift          # App entry point & deep link routing
│   └── NavigationDestination.swift
├── DaysWidget/                # Widget extension
│   ├── DaysWidget.swift       # Widget configurations (upcoming + pinned)
│   ├── Provider.swift         # AppIntentTimelineProvider
│   ├── DaySnapshot.swift      # Lightweight widget data model
│   ├── WidgetDataProvider.swift
│   ├── PinnedDayIntent.swift  # App Intent for widget configuration
│   └── WidgetSelection.swift  # Entity query for picking events
├── DaysTests/                 # Unit tests
├── DaysUITests/               # UI tests
└── Days.xcodeproj/
```

## License

All rights reserved.
