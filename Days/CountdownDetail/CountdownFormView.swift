//
//  CountdownFormView.swift
//  Days
//
//  Created by Ming Liang Khong on 23/3/26.
//

import SwiftUI
import SwiftData

struct CountdownFormView: View {
    @Bindable var viewModel: CountdownFormViewModel
    @State private var showCategoryPicker = false
    @State private var showIconPicker = false
    var countdown: Countdown? { nil }

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Enter title", text: $viewModel.name)
                    .frame(height: 36)
                    .accessibilityIdentifier("title_field")
            }

            Section(header: Text("Icon")) {
                Button {
                    showIconPicker = true
                } label: {
                    HStack {
                        if let iconName = viewModel.iconName {
                            Image(systemName: iconName)
                                .frame(width: 18)
                            Text("Selected")
                                .foregroundStyle(.primary)
                        } else {
                            Text("None")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Category")) {
                Button {
                    showCategoryPicker = true
                } label: {
                    HStack {
                        if let category = viewModel.selectedCategory {
                            Circle()
                                .fill(Color(hex: category.colorHex) ?? .gray)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .foregroundStyle(.primary)
                        } else {
                            Text("None")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Target Date")) {
                DatePicker(
                    "Date",
                    selection: $viewModel.targetDate,
                    displayedComponents: .date
                )

                Toggle("Include time", isOn: $viewModel.includeTime)

                if viewModel.includeTime {
                    DatePicker(
                        "Time",
                        selection: $viewModel.targetDate,
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section(header: Text("Repeat")) {
                Toggle("Recurring", isOn: $viewModel.isRecurring)

                if viewModel.isRecurring {
                    Picker("Repeat every", selection: $viewModel.recurringIntervalType) {
                        ForEach(RecurringIntervalType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if viewModel.recurringIntervalType == .custom {
                        Stepper("Every \(viewModel.recurringCustomDays) day(s)", value: $viewModel.recurringCustomDays, in: 1...365)
                    }

                    if viewModel.showEventTypePicker {
                        Picker("Event Type", selection: $viewModel.occasionType) {
                            Text("None").tag(OccasionType?.none)
                            ForEach(OccasionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(OccasionType?.some(type))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit" : "New Countdown")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.isEditing ? "Save" : "Add") {
                    viewModel.save()
                }
                .disabled(!viewModel.isValid)
                .accessibilityIdentifier(viewModel.isEditing ? "save_button" : "add_button")
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIconName: viewModel.iconName) { selected in
                viewModel.selectIcon(selected)
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: viewModel.recurringIntervalType) { _, new in
            if new != .annually { viewModel.occasionType = nil }
        }
        .onChange(of: viewModel.isRecurring) { _, new in
            if !new { viewModel.occasionType = nil }
        }
    }
}

private struct CountdownFormPreview: View {
    let countdown: Countdown?

    @State private var viewModel: CountdownFormViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel {
                CountdownFormView(viewModel: viewModel)
            }
        }
        .modelContainer(for: [Countdown.self, Category.self], inMemory: true)
        .onAppear {
            if viewModel == nil {
                do {
                    let container = try ModelContainer(for: Countdown.self, Category.self, configurations: .init(isStoredInMemoryOnly: true))
                    let modelContext = ModelContext(container)
                    let navigationViewModel = HomeViewModel(modelContext: modelContext)
                    viewModel = CountdownFormViewModel(
                        modelContext: modelContext,
                        countdown: countdown,
                        navigationViewModel: navigationViewModel,
                        navigateToDetailOnSave: false
                    )
                } catch {
                    print("Failed to create preview model container")
                }
            }
        }
    }
}

#Preview("New Countdown") {
    CountdownFormPreview(countdown: nil)
}

#Preview("Edit Countdown") {
    CountdownFormPreview(
        countdown: Countdown(
            name: "Trip to Kyoto",
            targetDate: .now.addingTimeInterval(86_400 * 30),
            includeTime: true
        )
    )
}
