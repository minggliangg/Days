//
//  CategoryPickerView.swift
//  Days
//

import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) var categories: [Category]

    @Binding var selectedCategory: Category?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex) ?? .gray)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCategorySheet { name, colorHex in
                    let category = createCategory(name: name, colorHex: colorHex)
                    selectedCategory = category
                    dismiss()
                }
            }
        }
    }

    private func createCategory(name: String, colorHex: String) -> Category {
        let maxSortOrder = categories.map(\.sortOrder).max() ?? -1
        let category = Category(name: name, colorHex: colorHex, sortOrder: maxSortOrder + 1)
        modelContext.insert(category)
        return category
    }
}

#Preview {
    CategoryPickerView(selectedCategory: .constant(nil))
        .modelContainer(for: Category.self, inMemory: true)
}
