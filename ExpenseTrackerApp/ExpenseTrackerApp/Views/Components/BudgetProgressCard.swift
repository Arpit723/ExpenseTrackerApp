//
//  BudgetProgressCard.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct BudgetProgressCard: View {
    let category: Category?
    let budget: Budget
    var showCategory: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            if showCategory {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: category?.icon ?? "folder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(category?.swiftUIColor ?? .gray)

                        Text(category?.name ?? "Overall Budget")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                    }

                    Spacer()

                    // Percentage Badge
                    Text(budget.progressPercentage.percentage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(budget.progressColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(budget.progressColor.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(budget.progressColor)
                        .frame(width: max(0, min(geometry.size.width * (budget.progressPercentage / 100), geometry.size.width)), height: 8)
                        .animation(.spring(response: 0.5), value: budget.progressPercentage)
                }
            }
            .frame(height: 8)

            // Details
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                    Text(budget.formattedSpent)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Budget")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                    Text(budget.formattedAmount)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }
            }

            // Remaining or Over Budget Warning
            if budget.isOverBudget {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Over budget by \(budget.formattedRemaining)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            } else {
                HStack {
                    Text("Remaining: \(budget.formattedRemaining)")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)

                    Spacer()

                    if budget.progressPercentage >= 90 {
                        Text("⚠️ Almost at limit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    } else if budget.progressPercentage >= 75 {
                        Text("⚡ Watch spending")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    } else {
                        Text("✅ On track")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    let mockData = MockDataService.shared
    VStack(spacing: 16) {
        ForEach(mockData.budgets.prefix(3)) { budget in
            BudgetProgressCard(
                category: mockData.category(for: budget.categoryId ?? UUID()),
                budget: budget
            )
        }
    }
    .padding()
    .background(Color.appBackground)
}
