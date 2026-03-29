//
//  AddBudgetView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Add Budget View
struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BudgetViewModel

    @State private var selectedCategory: Category?
    @State private var amountText: String = ""
    @State private var rollover: Bool = false
    @State private var isOverallBudget: Bool

    @FocusState private var isAmountFocused: Bool

    init(viewModel: BudgetViewModel, isOverallBudget: Bool = false) {
        self.viewModel = viewModel
        self._isOverallBudget = State(initialValue: isOverallBudget)
    }

    var body: some View {
        NavigationStack {
            Form {
                budgetTypeSection
                categorySelectionSection
                amountInputSection
                rolloverSection
                previewSection
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { viewModel.dismissError() }
            } message: {
                Text(viewModel.error?.errorDescription ?? "An error occurred")
            }
            .onAppear { isAmountFocused = true }
        }
    }

    // MARK: - Sections

    private var budgetTypeSection: some View {
        Section {
            Picker("Budget Type", selection: $isOverallBudget) {
                Text("Category Budget").tag(false)
                Text("Overall Budget").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: isOverallBudget) { _, newValue in
                if newValue { selectedCategory = nil }
            }
        } header: {
            Text("Budget Type")
        } footer: {
            Text(budgetTypeFooter)
        }
    }

    private var budgetTypeFooter: String {
        if isOverallBudget {
            return "Overall budget tracks total monthly spending."
        }
        return "Category budgets track spending for a specific category."
    }

    private var categorySelectionSection: some View {
        Group {
            if !isOverallBudget {
                Section("Category") {
                    if viewModel.categoriesWithoutBudget.isEmpty {
                        Text("All categories have budgets")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select a category").tag(nil as Category?)
                            ForEach(viewModel.categoriesWithoutBudget) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category as Category?)
                            }
                        }
                    }
                }
            }
        }
    }

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
                        quickAmountButton(amount: amount)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Budget Amount")
        } footer: {
            Text("Enter the maximum amount you want to spend.")
        }
    }

    private var rolloverSection: some View {
        Section("Options") {
            Toggle("Rollover unused budget", isOn: $rollover)

            if rollover {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.appPrimary)
                    Text("Unused budget will carry over to next month.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if let amount = parsedAmount, amount > 0 {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Preview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(previewTitle)
                            .font(.headline)
                        Spacer()
                        Text(amount.formattedAsCurrency())
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                    }

                    if rollover {
                        Label("Rollover enabled", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Helper Views

    private func quickAmountButton(amount: Double) -> some View {
        let isSelected = parsedAmount == amount
        return Button {
            amountText = String(format: "%.0f", amount)
        } label: {
            Text(amount.formattedAsCurrency())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .appPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.appPrimary : Color.appPrimary.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var quickAmounts: [Double] { [100, 250, 500, 750, 1000] }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var isValid: Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        if !isOverallBudget && selectedCategory == nil { return false }
        return true
    }

    private var previewTitle: String {
        if isOverallBudget {
            return "Overall Budget"
        }
        return selectedCategory?.name ?? "Select Category"
    }

    // MARK: - Actions

    private func saveBudget() {
        guard let amount = parsedAmount, amount > 0 else { return }

        do {
            try viewModel.addBudget(
                categoryId: isOverallBudget ? nil : selectedCategory?.id,
                amount: amount,
                rollover: rollover
            )
            dismiss()
        } catch {
            // Error handled by viewModel
        }
    }
}

// MARK: - Preview
#Preview {
    AddBudgetView(viewModel: BudgetViewModel())
}
