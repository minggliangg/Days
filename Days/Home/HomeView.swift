//
//  HomeView.swift
//  Days
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.deepLinkDestination) private var deepLinkDestination
    @Query(sort: \Countdown.targetDate) var countdowns: [Countdown]
    @Query(sort: \Category.sortOrder) var categories: [Category]
    @Query var occasions: [Occasion]

    @State private var viewModel: HomeViewModel?

    var body: some View {
        contentView
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                if let destination = deepLinkDestination, let viewModel {
                    viewModel.handleDeepLink(destination)
                }
            }
            .onChange(of: deepLinkDestination) { _, newValue in
                if let destination = newValue, let viewModel {
                    viewModel.handleDeepLink(destination)
                }
            }
    }

    private var contentView: some View {
        NavigationStack(path: navigationBinding) {
            ZStack {
                entryList
                addButton
            }
            .navigationTitle("Days")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CategoryManagerView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private var navigationBinding: Binding<[Destination]> {
        Binding(
            get: { viewModel?.navigationPath ?? [] },
            set: { viewModel?.navigationPath = $0 }
        )
    }

    private var allEntries: [AnyEntry] {
        var entries: [AnyEntry] = []
        entries.append(contentsOf: countdowns.map { AnyEntry.countdown($0) })
        entries.append(contentsOf: occasions.map { AnyEntry.occasion($0) })
        return entries.sorted { $0.nextDate < $1.nextDate }
    }

    private var filteredEntries: [AnyEntry] {
        switch viewModel?.selectedFilter {
        case .all:
            return allEntries
        case .occasions:
            return allEntries.filter { $0.isOccasion }
        case .category(let category):
            return allEntries.filter { $0.category?.id == category.id }
        case .none:
            return allEntries
        }
    }

    private var upcomingEntries: [AnyEntry] {
        filteredEntries.filter { !$0.isPast }
    }

    private var pastEntries: [AnyEntry] {
        filteredEntries.filter { $0.isPast }
    }

    private var entryList: some View {
        Group {
            if allEntries.isEmpty {
                emptyStateView
            } else {
                entriesList
            }
        }
        .navigationDestination(for: Destination.self) { destination in
            destinationView(for: destination)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Entries Yet")
                .font(.headline)
            Text("Tap + to add your first countdown or occasion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entriesList: some View {
        List {
            filterChipsSection

            if !upcomingEntries.isEmpty {
                Section {
                    ForEach(upcomingEntries) { entry in
                        entryRow(entry)
                    }
                }
            }
            if !pastEntries.isEmpty {
                Section("Past") {
                    ForEach(pastEntries) { entry in
                        entryRow(entry)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 8)
        }
    }

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(
                        title: "All",
                        isSelected: viewModel?.selectedFilter == .all
                    ) {
                        viewModel?.selectedFilter = .all
                    }

                    filterChip(
                        title: "Occasions",
                        isSelected: viewModel?.selectedFilter == .occasions
                    ) {
                        viewModel?.selectedFilter = .occasions
                    }

                    ForEach(categories) { category in
                        filterChip(
                            title: category.name,
                            color: Color(hex: category.colorHex) ?? .gray,
                            isSelected: {
                                if case .category(let cat) = viewModel?.selectedFilter {
                                    return cat.id == category.id
                                }
                                return false
                            }()
                        ) {
                            viewModel?.selectedFilter = .category(category)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func filterChip(title: String, color: Color = .gray, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("filter_\(title.lowercased())")
    }

    @ViewBuilder
    private func entryRow(_ entry: AnyEntry) -> some View {
        switch entry {
        case .countdown(let countdown):
            countdownRow(countdown)
        case .occasion(let occasion):
            occasionRow(occasion)
        }
    }

    private func countdownRow(_ countdown: Countdown) -> some View {
        Button {
            viewModel?.navigateToDetail(countdown)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(countdown.name)
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    LiveCountdownView(targetDate: countdown.targetDate, includeTime: countdown.includeTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let category = countdown.category {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(Color(hex: category.colorHex) ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("entry_\(countdown.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            deleteCountdownButton(countdown)
            editCountdownButton(countdown)
        }
    }

    private func occasionRow(_ occasion: Occasion) -> some View {
        Button {
            viewModel?.navigateToOccasionDetail(occasion)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(occasion.title)
                        .foregroundStyle(.primary)
                    if let personName = occasion.personName, !personName.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(personName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 4) {
                    LiveCountdownView(targetDate: occasion.nextOccurrenceDate, includeTime: false)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let category = occasion.category {
                        Circle()
                            .fill(Color(hex: category.colorHex) ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(iterationLabel(for: occasion))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("entry_\(occasion.title)")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            deleteOccasionButton(occasion)
            editOccasionButton(occasion)
        }
    }

    private func iterationLabel(for occasion: Occasion) -> String {
        let iteration = occasion.nextIteration
        switch occasion.occasionType {
        case .birthday:
            return "Turning \(iteration)"
        case .anniversary:
            let ordinal = ordinalString(for: iteration)
            return "\(ordinal) Anniversary"
        }
    }

    private func deleteCountdownButton(_ countdown: Countdown) -> some View {
        Button(role: .destructive) {
            viewModel?.deleteCountdown(countdown)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func editCountdownButton(_ countdown: Countdown) -> some View {
        Button {
            viewModel?.navigateToEdit(countdown)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.orange)
    }

    private func deleteOccasionButton(_ occasion: Occasion) -> some View {
        Button(role: .destructive) {
            viewModel?.deleteOccasion(occasion)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func editOccasionButton(_ occasion: Occasion) -> some View {
        Button {
            viewModel?.navigateToOccasionEdit(occasion)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.orange)
    }

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button {
                        viewModel?.navigateToAdd()
                    } label: {
                        Label("Countdown", systemImage: "calendar")
                    }
                    .accessibilityIdentifier("menu_countdown")

                    Button {
                        viewModel?.navigateToAddOccasion()
                    } label: {
                        Label("Occasion", systemImage: "gift")
                    }
                    .accessibilityIdentifier("menu_occasion")
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.tint)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
                }
                .accessibilityIdentifier("add_button")
                .padding()
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .detail(let countdownID):
            if let viewModel, let countdown = viewModel.fetchCountdown(by: countdownID) {
                CountdownDetailView(countdown: countdown, viewModel: viewModel)
            }
        case .edit(let countdownID):
            if let viewModel, let countdown = viewModel.fetchCountdown(by: countdownID) {
                CountdownFormView(
                    viewModel: CountdownFormViewModel(
                        modelContext: modelContext,
                        countdown: countdown,
                        navigationViewModel: viewModel,
                        navigateToDetailOnSave: true
                    )
                )
            }
        case .add:
            if let viewModel {
                CountdownFormView(
                    viewModel: CountdownFormViewModel(
                        modelContext: modelContext,
                        countdown: nil,
                        navigationViewModel: viewModel,
                        navigateToDetailOnSave: false
                    )
                )
            }
        case .addOccasion:
            if let viewModel {
                OccasionFormView(
                    viewModel: OccasionFormViewModel(
                        modelContext: modelContext,
                        occasion: nil,
                        navigationViewModel: viewModel
                    )
                )
            }
        case .occasionDetail(let occasionID):
            if let viewModel, let occasion = viewModel.fetchOccasion(by: occasionID) {
                OccasionDetailView(occasion: occasion, viewModel: viewModel)
            }
        case .occasionEdit(let occasionID):
            if let viewModel, let occasion = viewModel.fetchOccasion(by: occasionID) {
                OccasionFormView(
                    viewModel: OccasionFormViewModel(
                        modelContext: modelContext,
                        occasion: occasion,
                        navigationViewModel: viewModel
                    )
                )
            }
        }
    }
}

private func ordinalString(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

#Preview {
    HomeView()
        .modelContainer(for: [Countdown.self, Category.self, Occasion.self], inMemory: true)
}
