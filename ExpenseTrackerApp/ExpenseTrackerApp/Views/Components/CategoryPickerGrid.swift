//
//  CategoryPickerGrid.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct CategoryPickerGrid: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?

    private var nonSystemCategories: [Category] {
        categories.filter { !$0.isSystem }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(nonSystemCategories) { category in
                Button {
                    selectedCategory = category
                } label: {
                    CategoryIconView(
                        category: category,
                        isSelected: selectedCategory?.id == category.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CategoryIconView: View {
    let category: Category
    var isSelected: Bool = false
    var size: CGFloat = 60

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? category.swiftUIColor : category.swiftUIColor.opacity(0.15))
                    .frame(width: size, height: size)

                Image(systemName: category.icon)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundStyle(isSelected ? .white : category.swiftUIColor)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? category.swiftUIColor : Color.clear, lineWidth: 2)
            )

            Text(category.name)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview
#Preview {
    let dataService = DataService.shared
    CategoryPickerGrid(
        categories: dataService.categories,
        selectedCategory: .constant(dataService.categories.first)
    )
    .padding()
}
