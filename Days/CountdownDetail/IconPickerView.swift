//
//  IconPickerView.swift
//  Days
//

import SwiftUI

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedIconName: String?
    let onSelect: (String?) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    private let sections: [(title: String, icons: [String])] = [
        ("Celebrations", ["birthday.cake", "party.popper", "gift", "heart.fill", "heart.circle"]),
        ("Travel", ["airplane", "car", "tram.fill", "suitcase", "globe"]),
        ("Activities", ["music.note", "figure.run", "gamecontroller", "film", "fork.knife"]),
        ("People", ["person.3", "cross.case", "person.crop.circle", "graduationcap", "pencil.and.list.clipboard"]),
        ("Objects", ["calendar", "clock", "star.fill", "bell", "bookmark.fill"])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    clearButton

                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.headline)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(section.icons, id: \.self) { icon in
                                    iconButton(icon)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var clearButton: some View {
        Button {
            onSelect(nil)
        } label: {
            HStack {
                Image(systemName: "nosign")
                Text("None")
                Spacer()
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func iconButton(_ icon: String) -> some View {
        Button {
            onSelect(icon)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedIconName == icon ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedIconName == icon ? Color.accentColor : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedIconName == icon ? Color.accentColor : .primary)
    }
}
