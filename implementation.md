# Plan: Optional Event Images

## Context

Users want to attach photos to their countdown/occasion events. The image serves as a parallax hero on the detail screen and as a background (with heavy overlay) on widgets. Images are optional, sourced from Photos/Camera/Files, validated on import, and optimized for storage.

---

## 1. Image Storage & Processing Utility

**New file: `Days/Utils/ImageManager.swift`**

A stateless `enum ImageManager` that handles all image I/O:

- **Storage location**: `images/{uuid}.jpg` and `thumbnails/{uuid}.jpg` inside the shared app group container (`group.com.minggliangg.Days`) — widgets can access these directly
- **processAndSave(image:forEventID:)** → resizes to max 1200px longest edge, JPEG compresses at ~0.82 quality, saves full image + 300px thumbnail for widgets
- **validate(image:)** → returns `.tooSmall` (<50x50), `.tooLarge` (>10MB raw data), `.unreadable`, or `.valid` — advisory only, does not block
- **loadImage(relativePath:)** / **loadThumbnail(forEventID:)** — reads from app group container
- **deleteImage(forEventID:)** — removes both full + thumbnail files
- Creates `images/` and `thumbnails/` subdirectories lazily on first write

**Why files, not SwiftData blobs**: Avoids bloating the database, keeps it fast, and lets widgets read images without loading the full SwiftData graph. Models store only a relative path string.

**Why separate thumbnails**: Widgets have ~30MB memory limits. A 300px thumbnail at ~50-80KB is safe.

---

## 2. Model Changes

**`Days/Models/Countdown.swift`** — add `var imagePath: String?` property, default `nil` in `init`

**`Days/Models/Occasion.swift`** — add `var imagePath: String?` property, default `nil` in `init`

SwiftData handles lightweight migration for new optional properties automatically.

---

## 3. Image Picker UI Components

### 3a. Camera bridge
**New file: `Days/Components/CameraPickerView.swift`**

`UIViewControllerRepresentable` wrapping `UIImagePickerController` with `.camera` source. ~50 lines. Requires `NSCameraUsageDescription` in Info.plist.

### 3b. Reusable image picker section
**New file: `Days/Components/ImagePickerSection.swift`**

A `View` used in both form views. Contains:
- Thumbnail preview of current image (if set) with "Remove" button
- "Add Photo" button → `confirmationDialog` with 3 choices: "Photo Library", "Take Photo", "Choose File"
- Presents `PhotosPicker` (from PhotosUI), `CameraPickerView` sheet, or `.fileImporter` accordingly
- Advisory caption text for validation warnings (e.g., "Image is small and may appear blurry")
- Callbacks: `onImageSelected: (UIImage) -> Void`, `onImageRemoved: () -> Void`

---

## 4. Form ViewModel Integration

### `Days/CountdownDetail/CountdownFormViewModel.swift`
- Add `var selectedImage: UIImage?`, `var existingImagePath: String?`, `var imageRemoved: Bool = false`
- In `init` (edit mode): load existing image via `ImageManager.loadImage(relativePath:)`
- In `save()`:
  - If `imageRemoved`: call `ImageManager.deleteImage(forEventID:)`, set `countdown.imagePath = nil`
  - If `selectedImage` changed: call `ImageManager.processAndSave(image:forEventID:)`, set `countdown.imagePath`
  - For new countdowns: save image after `modelContext.insert` using `newCountdown.id`

### `Days/OccasionDetail/OccasionFormViewModel.swift`
- Same pattern: add `selectedImage`, `existingImagePath`, `imageRemoved`
- Handle in `save()` identically

### Form views
- **`Days/CountdownDetail/CountdownFormView.swift`** — add `ImagePickerSection` between Icon and Category sections, wired to viewModel
- **`Days/OccasionDetail/OccasionFormView.swift`** — same placement

---

## 5. Parallax Hero on Detail Views

**New file: `Days/Components/ParallaxHeroImage.swift`**

Reusable `ParallaxHeroImage` view using `GeometryReader` + `.scrollView` coordinate space (iOS 17+):
- Default height ~280pt
- Scroll down → image moves at 0.5x speed (parallax)
- Pull down (overscroll) → image stretches to fill
- Bottom gradient fade for smooth transition to content

### `Days/CountdownDetail/CountdownDetailView.swift`
- Add `@State private var loadedImage: UIImage?`, load in `onAppear` via `ImageManager.loadImage`
- When image present: wrap `CountdownContent` in `ScrollView` with `ParallaxHeroImage` above it, remove vertical `Spacer`s
- When no image: keep current centered layout unchanged

### `Days/OccasionDetail/OccasionDetailView.swift`
- Same approach: conditional `ScrollView` + `ParallaxHeroImage` when image exists

---

## 6. Widget Image Backgrounds

### `DaysWidget/DaySnapshot.swift`
- Add `let imagePath: String?` field

### `DaysWidget/WidgetDataProvider.swift`
- Pass `imagePath` from both Countdown and Occasion when constructing snapshots

### New file: `DaysWidget/WidgetImageLoader.swift`
- `loadThumbnail(forImagePath:)` — loads the 300px thumbnail from app group container
- Returns `nil` gracefully if file missing

### `DaysWidget/DaysWidgetEntryView.swift`
- **SmallContentView**: When `imagePath` is set and thumbnail loads, render as full background with heavy dark gradient overlay (`LinearGradient` from `.black.opacity(0.3)` → `.black.opacity(0.7)`). Switch text to `.white` foreground.
- **MediumRowView**: Similar background treatment per-row
- **containerBackground**: Use image as container background when available, fall back to `.thinMaterial`

---

## 7. Cleanup on Delete

**`Days/Home/HomeViewModel.swift`** — in `deleteCountdown` and `deleteOccasion`, call `ImageManager.deleteImage(forEventID:)` before `modelContext.delete()`

---

## 8. Info.plist

Add `NSCameraUsageDescription`: "Days uses the camera to let you take a photo for your events."

---

## 9. Files Summary

| File | Action |
|------|--------|
| `Days/Utils/ImageManager.swift` | **New** — core image processing/storage |
| `Days/Components/CameraPickerView.swift` | **New** — UIKit camera bridge |
| `Days/Components/ImagePickerSection.swift` | **New** — reusable picker form section |
| `Days/Components/ParallaxHeroImage.swift` | **New** — parallax scroll hero |
| `DaysWidget/WidgetImageLoader.swift` | **New** — widget thumbnail loader |
| `Days/Models/Countdown.swift` | **Edit** — add `imagePath: String?` |
| `Days/Models/Occasion.swift` | **Edit** — add `imagePath: String?` |
| `Days/CountdownDetail/CountdownFormViewModel.swift` | **Edit** — image state + save logic |
| `Days/OccasionDetail/OccasionFormViewModel.swift` | **Edit** — image state + save logic |
| `Days/CountdownDetail/CountdownFormView.swift` | **Edit** — add ImagePickerSection |
| `Days/OccasionDetail/OccasionFormView.swift` | **Edit** — add ImagePickerSection |
| `Days/CountdownDetail/CountdownDetailView.swift` | **Edit** — parallax hero + ScrollView |
| `Days/OccasionDetail/OccasionDetailView.swift` | **Edit** — parallax hero + ScrollView |
| `Days/Home/HomeViewModel.swift` | **Edit** — image cleanup on delete |
| `DaysWidget/DaySnapshot.swift` | **Edit** — add `imagePath` field |
| `DaysWidget/WidgetDataProvider.swift` | **Edit** — pass `imagePath` |
| `DaysWidget/DaysWidgetEntryView.swift` | **Edit** — image backgrounds |
| `Days/Info.plist` (or build settings) | **Edit** — camera permission |

---

## 10. Verification

1. **Build**: `xcodebuild -project Days.xcodeproj -scheme Days -destination 'platform=iOS Simulator,name=iPhone 16'`
2. **Unit tests**: `xcodebuild test -project Days.xcodeproj -scheme Days -destination 'platform=iOS Simulator,name=iPhone 16'`
3. **Manual testing**:
   - Create a countdown with image from each source (Photos, Camera, Files)
   - Verify parallax scroll on detail screen
   - Verify image appears in small and medium widgets
   - Edit event → change image → verify old image deleted
   - Edit event → remove image → verify fallback to no-image layout
   - Delete event → verify image files cleaned up
   - Verify events without images still display correctly (no regression)
   - Test validation: try importing a tiny image (<50px) and a very large image
