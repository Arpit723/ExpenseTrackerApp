//
//  AccountsView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showingAddAccount = false
    @State private var showingTransferSheet = false
    @State private var accountToDelete: Account?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Net Worth Card
                    netWorthCard

                    // MARK: - Summary Cards
                    summaryCardsRow

                    // MARK: - Search & Filter
                    searchAndFilterSection

                    // MARK: - Account Groups
                    ForEach(viewModel.groupedAccounts, id: \.0) { group in
                        accountGroupSection(type: group.0, accounts: group.1)
                    }

                    // MARK: - Add Account Button
                    addAccountButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.refreshAccounts()
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddAccount = true
                        } label: {
                            Label("Add Account", systemImage: "plus")
                        }

                        Button {
                            showingTransferSheet = true
                        } label: {
                            Label("Transfer", systemImage: "arrow.left.arrow.right")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddEditAccountView()
                    .onDisappear { viewModel.loadAccounts() }
            }
            .sheet(isPresented: $showingTransferSheet) {
                TransferView()
            }
            .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    accountToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete {
                        deleteAccount(account)
                    }
                }
            } message: {
                if let account = accountToDelete {
                    Text("Are you sure you want to delete '\(account.name)'? This will also delete all transactions in this account.")
                } else {
                    Text("Are you sure you want to delete this account?")
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Net Worth Card
    private var netWorthCard: some View {
        VStack(spacing: 16) {
            Text("Net Worth")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)

            Text(viewModel.netWorth.formattedAsCurrency())
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(viewModel.netWorth >= 0 ? .appSuccess : .appDanger)

            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: viewModel.netWorth >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                Text("+$2,450 from last month")
                    .font(.system(size: 13))
            }
            .foregroundColor(viewModel.netWorth >= 0 ? .appSuccess : .appDanger)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appSuccess.opacity(0.1), Color.appSuccess.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .stroke(Color.appSuccess.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Summary Cards Row
    private var summaryCardsRow: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Assets",
                amount: viewModel.totalAssets,
                color: .appSuccess,
                icon: "arrow.up.circle.fill"
            )

            SummaryCard(
                title: "Liabilities",
                amount: viewModel.totalLiabilities,
                color: .appDanger,
                icon: "arrow.down.circle.fill"
            )
        }
    }

    // MARK: - Search & Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)

                TextField("Search accounts...", text: $viewModel.searchText)
                    .font(.system(size: 14))

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(10)
            .background(Color.appCardBackground)
            .cornerRadius(10)

            // Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(
                        title: "All",
                        isSelected: viewModel.selectedType == nil
                    ) {
                        viewModel.selectedType = nil
                    }

                    ForEach(AccountType.allCases, id: \.self) { type in
                        FilterPill(
                            title: type.rawValue,
                            isSelected: viewModel.selectedType == type
                        ) {
                            viewModel.selectedType = type
                        }
                    }
                }
            }
        }
    }

    // MARK: - Account Group Section
    private func accountGroupSection(type: AccountType, accounts: [Account]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .frame(width: 20)

                Text(type.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text("\(accounts.count) accounts")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            // Accounts List
            VStack(spacing: 0) {
                ForEach(accounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        AccountRowView(
                            account: account,
                            onEdit: { editAccount(account) },
                            onDelete: { confirmDelete(account) }
                        )
                    }

                    if account.id != accounts.last?.id {
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

    // MARK: - Add Account Button
    private var addAccountButton: some View {
        Button(action: { showingAddAccount = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appPrimary)

                Text("Add New Account")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Actions

    private func editAccount(_ account: Account) {
        showingAddAccount = true
    }

    private func confirmDelete(_ account: Account) {
        accountToDelete = account
        showingDeleteConfirmation = true
    }

    private func deleteAccount(_ account: Account) {
        do {
            try viewModel.deleteAccount(account)
        } catch {
            // Error is shown via alert
        }
        accountToDelete = nil
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            Text(amount.formattedAsCurrency())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Account Row View (Enhanced)
struct AccountRowView: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(account.displayColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: account.type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(account.displayColor)
            }

            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    if !account.isActive {
                        Text("Inactive")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .cornerRadius(3)
                    }
                }

                if let institution = account.institution {
                    Text(institution)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
            }

            Spacer()

            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.formattedBalance)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(account.isNegative ? .appDanger : .appTextPrimary)

                // Show available credit for credit cards
                if let available = account.availableCredit {
                    Text("Avail: \(available.formattedAsCurrency())")
                        .font(.system(size: 10))
                        .foregroundColor(available >= 0 ? .appSuccess : .appDanger)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.appPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    AccountsView()
}
