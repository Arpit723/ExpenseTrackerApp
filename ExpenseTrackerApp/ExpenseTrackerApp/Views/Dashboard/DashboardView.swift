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

                    // MARK: - Monthly Summary
                    monthlySummarySection

                    // MARK: - Recent Transactions
                    recentTransactionsSection
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
                            .foregroundColor(.appPrimary)
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
        VStack(alignment: .leading, spacing: Constants.Layout.spacing) {
            Text("Total Balance")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Text(viewModel.totalBalance.formattedAsCurrency())
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
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
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Monthly Summary
    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

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
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recent Transactions (last 10 — FR-1.3)
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

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
                .foregroundColor(.appTextTertiary)

            Text("No transactions yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextSecondary)

            Button {
                showingAddTransaction = true
            } label: {
                Text("Add Transaction")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var transactionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                TransactionRow(
                    transaction: transaction,
                    category: viewModel.category(for: transaction.categoryId)
                )

                if index < viewModel.recentTransactions.count - 1 {
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

// MARK: - Preview
#Preview {
    DashboardView()
}
