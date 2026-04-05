//
//  AddTransactionView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TransactionViewModel()

    // Edit mode
    var editingTransaction: Transaction?

    // Form State
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate = Date()
    @State private var payee: String = ""
    @State private var notes: String = ""
    @State private var isExpense: Bool = true
    @State private var showingCategoryPicker: Bool = false

    // Computed Properties
    private var isEditMode: Bool {
        editingTransaction != nil
    }

    private var isValidForm: Bool {
        let amountValue = Double(amount) ?? 0
        return amountValue > 0 && selectedCategory != nil
    }

    // Initialize for add mode
    init() {
        self.editingTransaction = nil
    }

    // Initialize for edit mode
    init(transaction: Transaction) {
        self.editingTransaction = transaction
        _amount = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
        _selectedDate = State(initialValue: transaction.date)
        _payee = State(initialValue: transaction.payee ?? "")
        _notes = State(initialValue: transaction.notes ?? "")
        _isExpense = State(initialValue: transaction.isExpense)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Layout.spacing) {
                    // MARK: - Income/Expense Toggle (FR-2.1)
                    typeToggle

                    // MARK: - Amount Input
                    amountInputSection

                    // MARK: - Quick Amount Buttons
                    quickAmountButtons

                    // MARK: - Category Selection
                    categorySection

                    // MARK: - Date Selection
                    dateSection

                    // MARK: - Payee
                    payeeSection

                    // MARK: - Notes
                    notesSection

                    // MARK: - Save Button
                    saveButton
                }
                .padding(Constants.Layout.padding)
            }
            .background(Color.appBackground)
            .navigationTitle(isEditMode ? "Edit Transaction" : "Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(categories: viewModel.categories, selectedCategory: $selectedCategory)
            }
            .onAppear {
                if let transaction = editingTransaction {
                    // Pre-select category in edit mode
                    selectedCategory = viewModel.category(for: transaction)
                }
            }
        }
    }

    // MARK: - Type Toggle
    private var typeToggle: some View {
        HStack(spacing: 0) {
            Button(action: { isExpense = true }) {
                Text("Expense")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isExpense ? .white : .appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isExpense ? Color.appDanger : Color.clear)
                    .cornerRadius(Constants.Layout.buttonCornerRadius)
            }

            Button(action: { isExpense = false }) {
                Text("Income")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(!isExpense ? .white : .appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(!isExpense ? Color.appSuccess : Color.clear)
                    .cornerRadius(Constants.Layout.buttonCornerRadius)
            }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(Constants.Layout.buttonCornerRadius)
    }

    // MARK: - Amount Input
    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(amount.isEmpty ? .appTextTertiary : .appTextPrimary)

                TextField("0.00", text: $amount)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Quick Amount Buttons
    private var quickAmountButtons: some View {
        VStack(spacing: 8) {
            Text("Quick Amounts")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(Constants.quickAmounts, id: \.self) { value in
                    Button(action: {
                        amount = String(format: "%.0f", value)
                    }) {
                        Text("$\(Int(value))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(spacing: 8) {
            Text("Category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showingCategoryPicker = true }) {
                HStack(spacing: 12) {
                    if let category = selectedCategory {
                        ZStack {
                            Circle()
                                .fill(category.swiftUIColor.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                                .foregroundColor(category.swiftUIColor)
                        }

                        Text(category.name)
                            .font(.system(size: 15))
                            .foregroundColor(.appTextPrimary)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        Text("Select a category")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Payee Section
    private var payeeSection: some View {
        VStack(spacing: 8) {
            Text("Payee (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .foregroundColor(.appTextTertiary)

                TextField("e.g., Starbucks, Amazon", text: $payee)
                    .font(.system(size: 15))
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: 8) {
            Text("Notes (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .foregroundColor(.appTextTertiary)

                TextField("Add a note...", text: $notes)
                    .font(.system(size: 15))
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveTransaction) {
            Text(isEditMode ? "Update Transaction" : "Save Transaction")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isValidForm ? [Color.appPrimary, Color.appSecondary] : [Color.gray, Color.gray]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Constants.Layout.cardCornerRadius)
        }
        .disabled(!isValidForm)
    }

    // MARK: - Actions
    private func saveTransaction() {
        guard let amountValue = Double(amount),
              let category = selectedCategory,
              amountValue > 0 else { return }

        let finalAmount = isExpense ? -amountValue : amountValue

        if let existing = editingTransaction {
            var updated = existing
            updated.amount = finalAmount
            updated.categoryId = category.id
            updated.date = selectedDate
            updated.payee = payee.isEmpty ? nil : payee
            updated.notes = notes.isEmpty ? nil : notes
            viewModel.updateTransaction(updated)
        } else {
            let transaction = Transaction(
                amount: finalAmount,
                categoryId: category.id,
                date: selectedDate,
                payee: payee.isEmpty ? nil : payee,
                notes: notes.isEmpty ? nil : notes
            )
            viewModel.addTransaction(transaction)
        }

        dismiss()
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                CategoryPickerGrid(categories: categories, selectedCategory: $selectedCategory)
                    .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#Preview {
    AddTransactionView()
}
