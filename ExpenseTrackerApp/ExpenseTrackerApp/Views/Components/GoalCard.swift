//
//  GoalCard.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(goal.priority.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    Text(goal.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(goal.isCompleted ? .green : (goal.isOnTrack ? .appTextSecondary : .orange))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(goal.progressPercentage.percentage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(goal.isCompleted ? .green : .appPrimary)

                    if !goal.isCompleted {
                        Text("\(goal.daysRemaining)d left")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextTertiary)
                    }
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [goal.isCompleted ? Color.green : Color.appPrimary, goal.isCompleted ? Color.green : Color.appSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geometry.size.width * (goal.progressPercentage / 100), geometry.size.width)), height: 10)
                }
            }
            .frame(height: 10)

            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                    Text(goal.formattedCurrentAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("Target")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                    Text(goal.formattedTargetAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                    Text(goal.formattedRemaining)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }
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
        ForEach(mockData.goals) { goal in
            GoalCard(goal: goal)
        }
    }
    .padding()
    .background(Color.appBackground)
}
