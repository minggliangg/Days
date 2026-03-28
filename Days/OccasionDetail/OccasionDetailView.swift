//
//  OccasionDetailView.swift
//  Days
//

import SwiftUI
import SwiftData

struct OccasionDetailView: View {
    @Bindable var occasion: Occasion
    var viewModel: HomeViewModel

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: occasion.nextOccurrenceDate)
    }

    private var iterationLabel: String {
        let iteration = occasion.nextIteration
        let ordinal = ordinalString(for: iteration)
        switch occasion.occasionType {
        case .birthday:
            return "Turning \(iteration)"
        case .anniversary:
            return "\(ordinal) Anniversary"
        }
    }

    var body: some View {
        OccasionCountdownContent(
            iconName: occasion.iconName,
            targetDate: occasion.nextOccurrenceDate,
            displayDate: displayDate
        ) {
            OccasionSummaryBadge(
                personName: occasion.personName,
                iterationLabel: iterationLabel
            )
        }
        .navigationTitle(occasion.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: navigateToEdit) {
                    Image(systemName: "pencil")
                }
            }
        }
    }

    private func navigateToEdit() {
        viewModel.navigateToOccasionEdit(occasion)
    }
}

private struct OccasionSummaryBadge: View {
    let personName: String?
    let iterationLabel: String

    var body: some View {
        if let personName, !personName.isEmpty {
            OccasionSummaryCard(
                personName: personName,
                iterationLabel: iterationLabel
            )
        } else {
            OccasionSummaryCard(
                personName: nil,
                iterationLabel: iterationLabel
            )
        }
    }
}

private struct OccasionCountdownContent<SupplementaryContent: View>: View {
    let iconName: String?
    let targetDate: Date
    let displayDate: String
    @ViewBuilder let supplementaryContent: SupplementaryContent

    init(
        iconName: String?,
        targetDate: Date,
        displayDate: String,
        @ViewBuilder supplementaryContent: () -> SupplementaryContent
    ) {
        self.iconName = iconName
        self.targetDate = targetDate
        self.displayDate = displayDate
        self.supplementaryContent = supplementaryContent()
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            LiveCountdownView(targetDate: targetDate, includeTime: false)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Counting down to:")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(displayDate)
                .font(.title2)
                .multilineTextAlignment(.center)

            supplementaryContent

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct OccasionSummaryCard: View {
    let personName: String?
    let iterationLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.22),
                                    Color.pink.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: personName != nil ? "sparkles" : "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.orange.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(personName != nil ? "Celebrating" : "Occasion")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.orange.opacity(0.78))
                        .textCase(.uppercase)

                    if let personName {
                        Text(personName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Mark your calendar")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(iterationLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("A date worth holding onto.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.orange.opacity(0.08),
                                    Color.pink.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.orange.opacity(0.16),
                            Color.primary.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 72, height: 72)
                .blur(radius: 6)
                .offset(x: 18, y: -18)
        }
        .shadow(color: Color.orange.opacity(0.08), radius: 24, y: 10)
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }
}

private func ordinalString(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

#Preview("With Person Name") {
    @Previewable @State var viewModel: HomeViewModel? = nil
    NavigationStack {
        if let viewModel {
            OccasionDetailView(
                occasion: Occasion(
                    title: "Birthday",
                    occasionType: .birthday,
                    personName: "John Doe",
                    month: 6,
                    day: 15,
                    startYear: 1990
                ),
                viewModel: viewModel
            )
        }
    }
    .modelContainer(for: [Countdown.self, Category.self, Occasion.self], inMemory: true)
    .onAppear {
        if viewModel == nil {
            do {
                viewModel = HomeViewModel(modelContext: ModelContext(try .init(for: Countdown.self, Category.self, Occasion.self)))
            } catch {
                print("Failed to create model context")
            }
        }
    }
}

#Preview("Without Person Name") {
    @Previewable @State var viewModel: HomeViewModel? = nil
    NavigationStack {
        if let viewModel {
            OccasionDetailView(
                occasion: Occasion(
                    title: "Anniversary",
                    occasionType: .anniversary,
                    personName: nil,
                    month: 3,
                    day: 22,
                    startYear: 2015
                ),
                viewModel: viewModel
            )
        }
    }
    .modelContainer(for: [Countdown.self, Category.self, Occasion.self], inMemory: true)
    .onAppear {
        if viewModel == nil {
            do {
                viewModel = HomeViewModel(modelContext: ModelContext(try .init(for: Countdown.self, Category.self, Occasion.self)))
            } catch {
                print("Failed to create model context")
            }
        }
    }
}
