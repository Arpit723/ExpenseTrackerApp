//
//  DashboardView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Total Balance Card
                    balanceCard

                    // MARK: - Monthly Summary
                    monthlySummarySection

                    // MARK: - Quick Actions
                    quickActionsSection

                    // MARK: - Recent Transactions
                    recentTransactionsSection

                    // MARK: - Upcoming Bills
                    upcomingBillsSection

                    // MARK: - Daily Insight
                    dailyInsightCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100) // Space for FAB
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .onDisappear { viewModel.refreshData() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionAdded)) { _ in
                viewModel.refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionDeleted)) { _ in
                viewModel.refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                viewModel.refreshData()
            }
        }
    }

    // MARK: - Balance Card
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Balance")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))

                    Text(viewModel.totalBalance.formattedAsCurrency())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Net Worth Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Net Worth")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))

                    Text(viewModel.netWorth.formattedAsCurrency())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                Text("+$1,234 from last month")
                    .font(.system(size: 13))
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Monthly Summary
    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 16) {
                // Income vs Expenses
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                        Text(viewModel.totalIncomeThisMonth.formattedAsCurrency())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appSuccess)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Expenses")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                        Text(viewModel.totalExpensesThisMonth.formattedAsCurrency())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appDanger)
                    }
                }

                Divider()

                // Budget Progress
                if let overallBudget = viewModel.budget {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Used")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)

                            Spacer()

                            Text("\(Int(overallBudget.progressPercentage))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(overallBudget.progressColor)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(overallBudget.progressColor)
                                    .frame(width: geometry.size.width * min(overallBudget.progressPercentage / 100, 1), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(overallBudget.formattedRemaining) remaining")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add",
                    color: .appPrimary,
                    action: { showingAddTransaction = true }
                )

                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Reports",
                    color: .appSecondary,
                    action: {}
                )

                QuickActionButton(
                    icon: "target",
                    title: "Goals",
                    color: .appSuccess,
                    action: {}
                )

                QuickActionButton(
                    icon: "creditcard.fill",
                    title: "Accounts",
                    color: .appWarning,
                    action: {}
                )
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Spending")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                NavigationLink(destination: TransactionsView()) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
            }

            VStack(spacing: 0) {
                ForEach(viewModel.transactions.filter { $0.isToday }.prefix(5)) { transaction in
                    TransactionRow(
                        transaction: transaction,
                        category: viewModel.category(for: transaction.categoryId),
                        account: viewModel.account(for: transaction.accountId)
                    )

                    if transaction.id != viewModel.transactions.filter({ $0.isToday }).prefix(5).last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Upcoming Bills
    private var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Bills")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text("\(viewModel.recurringTransactions.filter { $0.isActive }.count) active")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.recurringTransactions.filter { $0.isActive && $0.daysUntilDue <= 7 }.prefix(3)) { recurring in
                    RecurringTransactionRow(
                        recurring: recurring,
                        category: viewModel.category(for: recurring.categoryId)
                    )

                    if recurring.id != viewModel.recurringTransactions.filter({ $0.isActive && $0.daysUntilDue <= 7 }).prefix(3).last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Daily Insight
    private var dailyInsightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)

                Text("Daily Insight")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            Text("You spent 20% less on dining out this week compared to last week. Keep up the great work! 🎉")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
