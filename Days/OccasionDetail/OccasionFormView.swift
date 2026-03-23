//
//  OccasionFormView.swift
//  Days
//

import SwiftUI
import SwiftData

struct OccasionFormView: View {
    @Bindable var viewModel: OccasionFormViewModel
    @State private var showCategoryPicker = false
    @State private var showIconPicker = false

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Enter title", text: $viewModel.title)
                    .frame(height: 36)
                    .accessibilityIdentifier("title_field")
            }

            Section(header: Text("Type")) {
                Picker("Occasion Type", selection: $viewModel.occasionType) {
                    ForEach(OccasionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section(header: Text("Person")) {
                TextField("Person's name (optional)", text: Binding(
                    get: { viewModel.personName ?? "" },
                    set: { viewModel.personName = $0.isEmpty ? nil : $0 }
                ))
                .frame(height: 36)
                .accessibilityIdentifier("person_field")
            }

            Section(header: Text("Date")) {
                if viewModel.iterationMode == .derived {
                    Text(viewModel.occasionType == .birthday ? "Date of birth" : "Start date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Event date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                DatePicker(
                    "Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }

            Section(header: Text("Age / Year Number")) {
                Picker("Mode", selection: $viewModel.iterationMode) {
                    Text("I know the year").tag(OccasionFormViewModel.IterationMode.derived)
                    Text("I know the #").tag(OccasionFormViewModel.IterationMode.manual)
                }
                .pickerStyle(.segmented)

                if viewModel.iterationMode == .manual {
                    Stepper(
                        viewModel.occasionType == .birthday
                            ? "They will be turning \(viewModel.manualIteration)"
                            : "\(viewModel.manualIteration)\(ordinalString(for: viewModel.manualIteration)) anniversary",
                        value: $viewModel.manualIteration,
                        in: 1...200
                    )
                }
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
        }
        .navigationTitle(viewModel.isEditing ? "Edit Occasion" : "New Occasion")
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
    }
}

private func ordinalString(for number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

#Preview("New Occasion") {
    @Previewable @State var viewModel: OccasionFormViewModel? = nil
    NavigationStack {
        if let viewModel {
            OccasionFormView(viewModel: viewModel)
        }
    }
    .modelContainer(for: [Countdown.self, Category.self, Occasion.self], inMemory: true)
    .onAppear {
        if viewModel == nil {
            do {
                let container = try ModelContainer(for: Countdown.self, Category.self, Occasion.self, configurations: .init(isStoredInMemoryOnly: true))
                let modelContext = ModelContext(container)
                let navigationViewModel = HomeViewModel(modelContext: modelContext)
                viewModel = OccasionFormViewModel(
                    modelContext: modelContext,
                    occasion: nil,
                    navigationViewModel: navigationViewModel
                )
            } catch {
                print("Failed to create preview model container")
            }
        }
    }
}
