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

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories.filter { !$0.isSystem }) { category in
                CategoryIconView(
                    category: category,
                    isSelected: selectedCategory?.id == category.id
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                    }
                }
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
                    .foregroundColor(isSelected ? .white : category.swiftUIColor)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? category.swiftUIColor : Color.clear, lineWidth: 2)
            )

            Text(category.name)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview
#Preview {
    let mockData = MockDataService.shared
    CategoryPickerGrid(
        categories: mockData.categories,
        selectedCategory: .constant(mockData.categories.first)
    )
    .padding()
}
