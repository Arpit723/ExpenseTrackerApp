//
//  EditBudgetView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Edit Budget View
struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BudgetViewModel

    @State private var budget: Budget
    @State private var amountText: String = ""
    @State private var rollover: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    @FocusState private var isAmountFocused: Bool

    let onDelete: (() -> Void)?

    init(viewModel: BudgetViewModel, budget: Budget, onDelete: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._budget = State(initialValue: budget)
        self._amountText = State(initialValue: String(format: "%.0f", budget.amount))
        self._rollover = State(initialValue: budget.rollover)
        self.onDelete = onDelete
    }

    // Quick amounts for budget
    private let quickAmounts: [Double] = [100, 250, 500, 750, 1000, 1500, 2000]

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var isValid: Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                categoryInfoSection
                amountInputSection
                rolloverSection
                currentStatusSection
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            saveBudget()
                        } label: {
                            Label("Save Changes", systemImage: "checkmark")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Budget?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBudget()
                }
            } message: {
                Text("This will permanently delete this budget. This action cannot be undone.")
            }
        }
    }

    // MARK: - Category Info Section
    private var categoryInfoSection: some View {
        Section {
            if let category = viewModel.category(for: budget) {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.swiftUIColor)
                        .frame(width: 40, height: 40)
                        .background(category.swiftUIColor.opacity(0.15))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.headline)
                        Text("Category Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.appPrimary.opacity(0.15))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overall Budget")
                            .font(.headline)
                        Text("All categories combined")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Budget For")
        }
    }

    // MARK: - Amount Input Section
    private var amountInputSection: some View {
        Section {
            HStack {
                Text("$")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("0", text: $amountText)
                    .font(.system(size: 34, weight: .bold))
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)

                Spacer()
            }
            .padding(.vertical, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button {
                            amountText = String(format: "%.0f", amount)
                        } label: {
                            Text(amount.formattedAsCurrency())
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appCardBackground)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Budget Amount")
        }
    }

    // MARK: - Rollover Section
    private var rolloverSection: some View {
        Section {
            Toggle(isOn: $rollover) {
                Text("Rollover unused budget")
            }

            if rollover {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unused budget will carry over to next month. Overspending will reduce next month's budget.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Options")
        }
    }

    // MARK: - Current Status Section
    private var currentStatusSection: some View {
        Section {
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(budget.progressPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(budget.progressColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(budget.progressColor)
                            .frame(width: min(geometry.size.width * (budget.progressPercentage / 100), geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Stats
            HStack(spacing: 16) {
                StatItem(title: "Budget", value: budget.amount.formattedAsCurrency(), color: .appPrimary)
                StatItem(title: "Spent", value: budget.actualSpent.formattedAsCurrency(), color: .appDanger)
                StatItem(title: "Remaining", value: budget.formattedRemaining, color: .appSuccess)
            }
        } header: {
            Text("Current Status")
        }
    }

    // MARK: - Actions

    private func saveBudget() {
        guard let amount = parsedAmount, amount > 0 else { return }

        var updatedBudget = budget
        updatedBudget.amount = amount
        updatedBudget.rollover = rollover

        do {
            try viewModel.updateBudget(updatedBudget)
            dismiss()
        } catch {
            // Error is handled by viewModel
        }
    }

    private func deleteBudget() {
        do {
            try viewModel.deleteBudget(budget)
            dismiss()
            onDelete?()
        } catch {
            // Error is handled by viewModel
        }
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    let viewModel = BudgetViewModel()
    if let budget = viewModel.categoryBudgets.first {
        EditBudgetView(viewModel: viewModel, budget: budget)
    } else {
        Text("No budgets available")
    }
}
