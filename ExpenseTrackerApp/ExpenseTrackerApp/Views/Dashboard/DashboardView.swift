//
//  DashboardView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Layout.spacing) {
                    // MARK: - Total Balance Card
                    balanceCard

                    // MARK: - Today's Spending Card
                    if viewModel.todaySpending > 0 {
                        todaySpendingCard
                    }

                    // MARK: - Monthly Summary
                    monthlySummarySection

                    // MARK: - Category Spending
                    if !viewModel.categorySpending.isEmpty {
                        categorySpendingSection
                    }

                    // MARK: - Recent Transactions or Welcome Card
                    if !viewModel.hasTransactions {
                        welcomeCard
                    } else {
                        recentTransactionsSection
                    }
                }
                .padding(.horizontal, Constants.Layout.padding)
                .padding(.top, Constants.Layout.smallSpacing)
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
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }

    // MARK: - Balance Card
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.spacing) {
            Text("Total Balance")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))

            Text(viewModel.totalBalance.formattedAsCurrency())
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Layout.padding)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Monthly Summary
    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(viewModel.totalIncomeThisMonth.formattedAsCurrency())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.appSuccess)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expenses")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(viewModel.totalExpensesThisMonth.formattedAsCurrency())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.appDanger)
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Today's Spending Card
    private var todaySpendingCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Spending")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
                Text(viewModel.todaySpending.formattedAsCurrency())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.appDanger)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.appDanger.opacity(0.6))
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Category Spending Section
    private var categorySpendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)

            ForEach(viewModel.categorySpending, id: \.category.id) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: item.category.color) ?? .gray)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.category.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextPrimary)
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()

                    Text(item.amount.formattedAsCurrency())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Color.appPrimary)

            Text("Welcome to Expense Tracker!")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Start tracking your spending by adding your first transaction.")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddTransaction = true
            } label: {
                Text("Add Your First Transaction")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
            }
        }
        .padding(24)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recent Transactions (last 10 — FR-1.3)
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()
            }

            if viewModel.recentTransactions.isEmpty {
                emptyTransactionsPlaceholder
            } else {
                transactionsList
            }
        }
    }

    private var emptyTransactionsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Color.appTextTertiary)

            Text("No transactions yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            Button {
                showingAddTransaction = true
            } label: {
                Text("Add Transaction")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var transactionsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recentTransactions) { transaction in
                TransactionRow(
                    transaction: transaction,
                    category: viewModel.category(for: transaction.categoryId)
                )

                if transaction.id != viewModel.recentTransactions.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appCardBackground)
        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
