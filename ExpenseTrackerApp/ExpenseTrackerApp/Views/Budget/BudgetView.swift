//
//  BudgetView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Month Navigator
                    monthNavigator

                    // MARK: - Overall Budget Card
                    if let overallBudget = viewModel.overallBudget {
                        overallBudgetCard(overallBudget)
                    } else {
                        addOverallBudgetCard
                    }

                    // MARK: - Budget Health Status
                    budgetHealthStatusCard

                    // MARK: - Category Budgets
                    categoryBudgetsSection

                    // MARK: - Spending Insights
                    spendingInsightsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingAddBudget = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshBudgets()
            }
            .sheet(isPresented: $viewModel.showingAddBudget) {
                AddBudgetView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $viewModel.editingBudget) { budget in
                EditBudgetView(viewModel: viewModel, budget: budget) {
                    // Callback after delete
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.errorDescription ?? "An error occurred")
                }
            }
        }
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button(action: { viewModel.navigateToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.appTextPrimary)
                    .padding(12)
                    .background(Color.appCardBackground)
                    .cornerRadius(10)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.monthYearString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 4) {
                    if viewModel.isPastMonth {
                        Text("Past Month")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    } else if viewModel.isFutureMonth {
                        Text("Future Month")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    } else {
                        Text("Current Month")
                            .font(.system(size: 12))
                            .foregroundColor(.appSuccess)
                    }

                    if !viewModel.isCurrentMonth {
                        Button("Today") {
                            viewModel.navigateToCurrentMonth()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.appPrimary)
                    }
                }
            }

            Spacer()

            Button(action: { viewModel.navigateToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextPrimary)
                    .padding(12)
                    .background(Color.appCardBackground)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Overall Budget Card
    private func overallBudgetCard(_ budget: Budget) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Total Budget")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text(budget.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }

            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: min(budget.progressPercentage / 100, 1))
                    .stroke(
                        budget.progressColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: budget.progressPercentage)

                VStack(spacing: 4) {
                    Text("\(Int(budget.progressPercentage))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(budget.progressColor)

                    Text("Used")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
            }

            // Details
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(budget.formattedSpent)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text("Spent")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(budget.formattedRemaining)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(budget.isOverBudget ? .red : .appSuccess)
                    Text("Remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
            }

            // Warning if over budget
            if budget.isOverBudget {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("You've exceeded your budget by \(budget.formattedOverBudgetAmount)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture {
            viewModel.editingBudget = budget
        }
    }

    // MARK: - Add Overall Budget Card
    private var addOverallBudgetCard: some View {
        Button(action: {
            viewModel.showingAddBudget = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.appPrimary)

                Text("Set Overall Budget")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Text("Track your total monthly spending")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Budget Health Status Card
    private var budgetHealthStatusCard: some View {
        let status = viewModel.budgetHealthStatus

        return HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.system(size: 24))
                .foregroundColor(status.color)
                .frame(width: 44, height: 44)
                .background(status.color.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Text(status.message)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Category Budgets Section
    private var categoryBudgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category Budgets")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if !viewModel.categoriesWithoutBudget.isEmpty {
                    Button(action: { viewModel.showingAddBudget = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                    }
                }
            }

            if viewModel.categoryBudgets.isEmpty {
                emptyBudgetsCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.categoryBudgets) { budget in
                        BudgetProgressCard(
                            category: viewModel.category(for: budget),
                            budget: budget
                        )
                        .onTapGesture {
                            viewModel.editingBudget = budget
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty Budgets Card
    private var emptyBudgetsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 36))
                .foregroundColor(.appTextTertiary)

            Text("No Category Budgets")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextPrimary)

            Text("Add budgets for specific categories to track spending")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: { viewModel.showingAddBudget = true }) {
                Text("Add Category Budget")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }

    // MARK: - Spending Insights
    private var spendingInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 12) {
                insightRow(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    title: "Under Budget Categories",
                    value: "\(viewModel.categoryBudgets.filter { !$0.isOverBudget && $0.progressPercentage < 75 }.count) categories"
                )

                insightRow(
                    icon: "exclamationmark.circle.fill",
                    color: .orange,
                    title: "Near Limit",
                    value: "\(viewModel.categoryBudgets.filter { !$0.isOverBudget && $0.progressPercentage >= 75 }.count) categories"
                )

                insightRow(
                    icon: "xmark.circle.fill",
                    color: .red,
                    title: "Over Budget",
                    value: "\(viewModel.categoryBudgets.filter { $0.isOverBudget }.count) categories"
                )

                Divider()

                insightRow(
                    icon: "calendar",
                    color: .appPrimary,
                    title: "Avg. Daily Spending",
                    value: viewModel.averageDailySpending.formattedAsCurrency()
                )

                if viewModel.isCurrentMonth {
                    insightRow(
                        icon: "crystalball",
                        color: .purple,
                        title: "Projected Monthly",
                        value: viewModel.projectedMonthlySpending.formattedAsCurrency()
                    )
                }
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    private func insightRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appTextSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    BudgetView()
}
