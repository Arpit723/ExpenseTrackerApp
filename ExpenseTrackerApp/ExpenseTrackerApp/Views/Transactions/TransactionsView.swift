//
//  TransactionsView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var showingAddTransaction = false
    @State private var transactionToEdit: Transaction?
    @State private var showingDeleteConfirmation = false
    @State private var transactionToDelete: Transaction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header Stats
                headerStats

                // MARK: - Search and Filter
                searchAndFilterSection

                // MARK: - Transactions List
                transactionsList
            }
            .background(Color.appBackground)
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .onDisappear { viewModel.loadTransactions() }
            }
            .sheet(item: $transactionToEdit) { transaction in
                AddTransactionView(transaction: transaction)
                    .onDisappear { viewModel.loadTransactions() }
            }
            .alert("Delete Transaction?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    transactionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let transaction = transactionToDelete {
                        viewModel.deleteTransaction(transaction)
                    }
                    transactionToDelete = nil
                }
            } message: {
                if let transaction = transactionToDelete {
                    Text("Are you sure you want to delete '\(transaction.payee ?? "this transaction")'?")
                } else {
                    Text("Are you sure you want to delete this transaction?")
                }
            }
        }
    }

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.system(size: 10))
                            .foregroundColor(.appTextTertiary)
                        Text(viewModel.totalIncomeThisMonth.formattedAsCurrency())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appSuccess)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.system(size: 10))
                            .foregroundColor(.appTextTertiary)
                        Text(abs(viewModel.totalExpensesThisMonth).formattedAsCurrency())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appDanger)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Net")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextTertiary)
                Text(viewModel.netThisMonth.formattedAsCurrency())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.netThisMonth >= 0 ? .appSuccess : .appDanger)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
    }

    // MARK: - Search and Filter
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar (FR-2.5)
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextTertiary)

                TextField("Search transactions...", text: $viewModel.searchText)
                    .font(.system(size: 15))

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextTertiary)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Filter Chips (FR-2.6: All / Income / Expense only)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: viewModel.selectedFilter == filter,
                            action: { viewModel.selectedFilter = filter }
                        )
                    }

                    Spacer()

                    Menu {
                        ForEach(TransactionSort.allCases, id: \.self) { sort in
                            Button(action: { viewModel.selectedSort = sort }) {
                                HStack {
                                    Text(sort.title)
                                    if viewModel.selectedSort == sort {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(viewModel.selectedSort.title)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    // MARK: - Transactions List
    private var transactionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.groupedTransactions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.groupedTransactions, id: \.0) { group in
                        transactionGroupSection(group: group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshTransactions()
        }
    }

    // MARK: - Empty State (NFR-3.3)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.appTextTertiary)

            Text("No Transactions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            Text("Add your first transaction to get started")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)

            Button(action: { showingAddTransaction = true }) {
                Text("Add Transaction")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary)
                    .cornerRadius(10)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Transaction Group Section
    private func transactionGroupSection(group: (String, [Transaction])) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack {
                Text(group.0)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextSecondary)

                Spacer()

                let groupTotal = group.1.reduce(0) { $0 + $1.amount }
                Text(groupTotal.formattedAsCurrency())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(groupTotal >= 0 ? .appSuccess : .appDanger)
            }

            // Transactions
            VStack(spacing: 0) {
                ForEach(group.1) { transaction in
                    TransactionRow(
                        transaction: transaction,
                        category: viewModel.category(for: transaction)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        transactionToEdit = transaction
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            transactionToDelete = transaction
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            transactionToEdit = transaction
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.appPrimary)
                    }

                    if transaction.id != group.1.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.gray.opacity(0.15))
                )
        }
    }
}

// MARK: - Preview
#Preview {
    TransactionsView()
}
