# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
# Build
xcodebuild -project Days.xcodeproj -scheme Days -destination 'platform=iOS Simulator,name=iPhone 16'

# Run all unit tests
xcodebuild test -project Days.xcodeproj -scheme Days -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a specific test class
xcodebuild test -project Days.xcodeproj -scheme Days -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DaysTests/HomeViewModelTests
```

Tests use **Swift Testing** (not XCTest). Unit tests use in-memory SwiftData containers.

## Architecture

**Targets:** `Days` (app), `DaysWidget` (widget extension), `DaysTests`, `DaysUITests`

**Stack:** SwiftUI + SwiftData + `@Observable` (Swift 5.9 macro). No UIKit, no Combine.

### Models (`Days/Models/`)

- `Countdown` — main countdown with `targetDate`, `icon`, `Category`, recurring interval
- `Occasion` — annual recurring event (birthday/anniversary) with optional `personName`, `month`/`day`
- `Category` — tag with color and sort order; has relationships to both `Countdown` and `Occasion`
- `AnyEntry` — discriminated union enum (`Countdown | Occasion`) used for unified list display in Home

### MVVM Pattern

Views are SwiftUI structs. ViewModels are `@Observable` classes that hold form state and call `modelContext` directly. `HomeViewModel` owns the navigation path (`[Destination]`) and is passed down to child ViewModels.

### Data Flow

1. `SharedModelContainer.initializeContainer()` creates the SwiftData stack with app group `group.com.minggliangg.Days` (shared with widget)
2. On launch, migration routines run (`assignMissingCountdownIDsIfNeeded`, `migrateExistingOccasionsIfNeeded`)
3. `RecurringAdvancer.advanceIfNeeded()` auto-advances recurring countdowns past their target date
4. Views fetch via `@Query`; mutations call `modelContext.insert/delete/save` then `WidgetCenter.shared.reloadAllTimelines()`

### Navigation & Deep Links

Navigation uses `NavigationStack` with a `Destination` enum. Deep link scheme: `days://add`, `days://countdown/<uuid>`, `days://occasion/<uuid>`. Routing lives in `DaysApp.swift`.

### Widgets (`DaysWidget/`)

Two widgets are defined in `DaysWidgetBundle.swift`:

- **UpcomingDaysWidget** — shows nearest event(s); small (1 event) and medium (2 events) families. Uses `UpcomingDaysProvider` (plain `TimelineProvider`).
- **PinnedDayWidget** — shows a single user-configured event; small only. Uses `PinnedDayProvider` (`AppIntentTimelineProvider`) with `PinnedEventIntent`.

**Data flow:** `WidgetDataProvider.loadSnapshots()` fetches from the shared SwiftData container and returns `[DaySnapshot]`. `WidgetSelection` picks which snapshots to display. `DayEntity` / `DayEntityQuery` in `PinnedDayIntent.swift` power the widget configuration UI (user picks which event to pin).
