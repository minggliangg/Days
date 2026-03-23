//
//  CategoryManagerView.swift
//  Days
//

import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CategoryManagerViewModel?
    @State private var showAddSheet = false
    @State private var showDeleteConfirmation: Category?
    @State private var editingCategory: Category?
    @State private var editingName = ""

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.categories) { category in
                    categoryRow(category, viewModel: viewModel)
                }
                .onMove { source, destination in
                    viewModel.moveCategory(from: source, to: destination)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let category = viewModel.categories[index]
                        if category.countdowns.isEmpty {
                            viewModel.deleteCategory(category)
                        } else {
                            showDeleteConfirmation = category
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CategoryManagerViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCategorySheet { name, colorHex in
                _ = viewModel?.createCategory(name: name, colorHex: colorHex)
            }
        }
        .alert("Rename Category", isPresented: .init(
            get: { editingCategory != nil },
            set: { if !$0 { editingCategory = nil } }
        )) {
            TextField("Name", text: $editingName)
            Button("Cancel", role: .cancel) {
                editingCategory = nil
            }
            Button("Save") {
                if editingCategory != nil {
                    editingCategory?.name = editingName
                }
                editingCategory = nil
            }
        }
        .alert("Delete Category?", isPresented: .init(
            get: { showDeleteConfirmation != nil },
            set: { if !$0 { showDeleteConfirmation = nil } }
        ), presenting: showDeleteConfirmation) { category in
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = nil
            }
            Button("Delete", role: .destructive) {
                if let viewModel {
                    viewModel.deleteCategory(category)
                }
                showDeleteConfirmation = nil
            }
        } message: { category in
            Text("\(category.countdowns.count) countdown(s) will be uncategorized.")
        }
    }

    private func categoryRow(_ category: Category, viewModel: CategoryManagerViewModel) -> some View {
        HStack {
            Circle()
                .fill(Color(hex: category.colorHex) ?? .gray)
                .frame(width: 12, height: 12)
            Text(category.name)
            Spacer()
            Text("\(viewModel.countdownCountForCategory(category))")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingCategory = category
            editingName = category.name
        }
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor: Color = .blue

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue,
        .indigo, .purple, .pink, .brown, .gray
    ]

    let onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(name, selectedColor.hexString)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

#Preview {
    NavigationStack {
        CategoryManagerView()
    }
    .modelContainer(for: Category.self, inMemory: true)
}
