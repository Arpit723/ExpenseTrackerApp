//
//  AccountDetailView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI
import Charts

// MARK: - Account Detail View
struct AccountDetailView: View {
    @StateObject private var viewModel = AccountViewModel()
    @Environment(\.dismiss) private var dismiss

    let account: Account

    // UI State
    @State private var showingEditSheet = false
    @State private var showingTransferSheet = false
    @State private var showingAdjustBalanceSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText: String = ""

    // Computed properties
    private var transactions: [Transaction] {
        var result = viewModel.transactionsForAccount(account.id)

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .expenses:
            result = result.filter { $0.isExpense }
        case .income:
            result = result.filter { $0.isIncome }
        case .transfers:
            result = result.filter { viewModel.category(for: $0.categoryId)?.name == "Transfer" }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter { transaction in
                let payeeMatch = transaction.payee?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                return payeeMatch || notesMatch
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { $0.dateGroupTitle }
        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]

        return grouped.sorted { pair1, pair2 in
            if let idx1 = groupOrder.firstIndex(of: pair1.key),
               let idx2 = groupOrder.firstIndex(of: pair2.key) {
                return idx1 < idx2
            }
            return pair1.key > pair2.key
        }
    }

    private var spendingTrend: [Double] {
        viewModel.spendingTrendLast7Days(for: account.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header Card
                headerCard

                // MARK: - Statistics
                statisticsSection

                // MARK: - Spending Trend Chart
                if !spendingTrend.isEmpty {
                    spendingTrendSection
                }

                // MARK: - Quick Actions
                quickActionsSection

                // MARK: - Transactions
                transactionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color.appBackground)
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Account", systemImage: "pencil")
                    }

                    Button {
                        showingTransferSheet = true
                    } label: {
                        Label("Transfer", systemImage: "arrow.left.arrow.right")
                    }

                    Button {
                        showingAdjustBalanceSheet = true
                    } label: {
                        Label("Adjust Balance", systemImage: "slider.horizontal.3")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditAccountView(account: account)
                .onDisappear { viewModel.loadAccounts() }
        }
        .sheet(isPresented: $showingTransferSheet) {
            TransferView(sourceAccount: account)
        }
        .sheet(isPresented: $showingAdjustBalanceSheet) {
            AdjustBalanceView(account: account, viewModel: viewModel)
        }
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. If this account has transactions, you'll need to delete them first.")
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(account.displayColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: account.type.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(account.displayColor)
            }

            // Name & Institution
            VStack(spacing: 4) {
                Text(account.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                if let institution = account.institution {
                    HStack(spacing: 4) {
                        Text(institution)
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)

                        if let accountNum = account.formattedAccountNumber {
                            Text("• \(accountNum)")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }

            // Balance
            Text(account.formattedBalance)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(account.isNegative ? .appDanger : .appTextPrimary)

            // Available Credit (for credit cards)
            if let available = account.availableCredit {
                HStack(spacing: 4) {
                    Text("Available Credit:")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)

                    Text(available.formattedAsCurrency())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(available >= 0 ? .appSuccess : .appDanger)
                }

                // Credit utilization bar
                if let utilization = account.creditUtilization {
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(utilizationColor(utilization))
                                    .frame(width: geometry.size.width * min(utilization, 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(Int(utilization * 100))% credit utilized")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Status badge
            if !account.isActive {
                Text("Inactive")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func utilizationColor(_ utilization: Double) -> Color {
        if utilization < 0.3 {
            return .appSuccess
        } else if utilization < 0.7 {
            return .appWarning
        } else {
            return .appDanger
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 12) {
                StatCard(
                    title: "Spending",
                    value: viewModel.spendingThisMonth(for: account.id),
                    color: .appDanger,
                    icon: "arrow.down.circle.fill"
                )

                StatCard(
                    title: "Income",
                    value: viewModel.incomeThisMonth(for: account.id),
                    color: .appSuccess,
                    icon: "arrow.up.circle.fill"
                )

                StatCard(
                    title: "Transactions",
                    value: Double(viewModel.transactionCount(for: account.id)),
                    color: .appPrimary,
                    icon: "list.bullet.circle.fill",
                    isCount: true
                )
            }
        }
    }

    // MARK: - Spending Trend
    private var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            Chart(Array(spendingTrend.enumerated()), id: \.offset) { index, value in
                BarMark(
                    x: .value("Day", index),
                    y: .value("Spending", value)
                )
                .foregroundStyle(account.displayColor.gradient)
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "pencil.circle.fill",
                title: "Edit",
                color: .appPrimary
            ) {
                showingEditSheet = true
            }

            QuickActionButton(
                icon: "arrow.left.arrow.right.circle.fill",
                title: "Transfer",
                color: .appSecondary
            ) {
                showingTransferSheet = true
            }

            QuickActionButton(
                icon: "slider.horizontal.3",
                title: "Adjust",
                color: .appWarning
            ) {
                showingAdjustBalanceSheet = true
            }
        }
    }

    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with search and filter
            HStack {
                Text("Transactions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text("\(transactions.count)")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
            }

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)

                TextField("Search transactions...", text: $searchText)
                    .font(.system(size: 14))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(10)
            .background(Color.appCardBackground)
            .cornerRadius(10)

            // Transactions List
            if transactions.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(groupedTransactions, id: \.0) { group in
                        TransactionGroupView(
                            title: group.0,
                            transactions: group.1,
                            viewModel: viewModel
                        )
                    }
                }
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.appTextSecondary)

            Text("No Transactions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextPrimary)

            Text("Transactions for this account will appear here.")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }

    private func deleteAccount() {
        do {
            try viewModel.deleteAccount(account)
            dismiss()
        } catch {
            // Error is handled by viewModel
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    var isCount: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }

            Text(isCount ? "\(Int(value))" : value.formattedAsCurrency())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cornerRadius)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.appPrimary : Color.appCardBackground)
                .cornerRadius(16)
        }
    }
}

// MARK: - Transaction Group View
struct TransactionGroupView: View {
    let title: String
    let transactions: [Transaction]
    let viewModel: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group Header
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextSecondary)

                Spacer()

                let total = transactions.reduce(0) { $0 + $1.amount }
                Text(total.formattedAsCurrency())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(total < 0 ? .appDanger : .appSuccess)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appBackground.opacity(0.5))

            // Transactions
            ForEach(transactions) { transaction in
                TransactionRow(
                    transaction: transaction,
                    category: viewModel.category(for: transaction.categoryId),
                    account: nil  // Don't show account since we're in account detail
                )

                if transaction.id != transactions.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
    }
}

// MARK: - Adjust Balance View
struct AdjustBalanceView: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let viewModel: AccountViewModel

    @State private var newBalance: String = ""
    @State private var adjustmentNote: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Balance") {
                    Text(account.formattedBalance)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(account.isNegative ? .appDanger : .appTextPrimary)
                }

                Section("New Balance") {
                    HStack {
                        Text("$")
                            .foregroundColor(.appTextSecondary)
                        TextField("0.00", text: $newBalance)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .bold))
                    }

                    if let newAmount = Double(newBalance) {
                        let difference = newAmount - account.balance
                        HStack {
                            Text("Adjustment:")
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                            Text((difference >= 0 ? "+" : "") + difference.formattedAsCurrency())
                                .foregroundColor(difference >= 0 ? .appSuccess : .appDanger)
                        }
                    }

                    TextField("Note (optional)", text: $adjustmentNote)
                }
            }
            .navigationTitle("Adjust Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newAmount = Double(newBalance) {
                            viewModel.adjustBalance(for: account, newBalance: newAmount)
                            dismiss()
                        }
                    }
                    .disabled(Double(newBalance) == nil)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AccountDetailView(account: Account.previewAccounts[0])
    }
}
