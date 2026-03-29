//
//  TransferView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Transfer View
struct TransferView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AccountViewModel()

    // Source account (can be pre-selected)
    let sourceAccount: Account?

    // State
    @State private var selectedSourceAccount: Account?
    @State private var selectedDestinationAccount: Account?
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()

    // UI State
    @State private var showingSourcePicker = false
    @State private var showingDestinationPicker = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    // Quick amounts
    private let quickAmounts: [Double] = [50, 100, 250, 500, 1000]

    var isValid: Bool {
        selectedSourceAccount != nil &&
        selectedDestinationAccount != nil &&
        selectedSourceAccount?.id != selectedDestinationAccount?.id &&
        Double(amount) ?? 0 > 0
    }

    init(sourceAccount: Account? = nil) {
        self.sourceAccount = sourceAccount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Amount Input
                    amountInputSection

                    // MARK: - Account Selection
                    accountSelectionSection

                    // MARK: - Quick Amounts
                    quickAmountsSection

                    // MARK: - Date & Notes
                    additionalDetailsSection

                    // MARK: - Transfer Button
                    transferButton
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let source = sourceAccount {
                    selectedSourceAccount = source
                }
            }
            .alert("Transfer Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Transfer Successful", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let source = selectedSourceAccount, let dest = selectedDestinationAccount,
                   let amountValue = Double(amount) {
                    Text("\(amountValue.formattedAsCurrency()) transferred from \(source.name) to \(dest.name)")
                }
            }
        }
    }

    // MARK: - Amount Input Section
    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                TextField("0.00", text: $amount)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }

    // MARK: - Account Selection Section
    private var accountSelectionSection: some View {
        VStack(spacing: 16) {
            // From Account
            accountSelectorCard(
                title: "From",
                account: selectedSourceAccount,
                icon: "arrow.up.circle.fill",
                color: .appDanger
            ) {
                showingSourcePicker = true
            }

            // Swap Button
            Button {
                swapAccounts()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.appCardBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.1), radius: 4)

                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
            }
            .disabled(selectedSourceAccount == nil || selectedDestinationAccount == nil)
            .opacity(selectedSourceAccount == nil || selectedDestinationAccount == nil ? 0.5 : 1)

            // To Account
            accountSelectorCard(
                title: "To",
                account: selectedDestinationAccount,
                icon: "arrow.down.circle.fill",
                color: .appSuccess
            ) {
                showingDestinationPicker = true
            }
        }
        .sheet(isPresented: $showingSourcePicker) {
            AccountPickerView(
                accounts: viewModel.transferableAccounts,
                selectedAccount: $selectedSourceAccount,
                excludeAccountId: selectedDestinationAccount?.id,
                title: "Select Source Account"
            )
        }
        .sheet(isPresented: $showingDestinationPicker) {
            AccountPickerView(
                accounts: viewModel.transferableAccounts,
                selectedAccount: $selectedDestinationAccount,
                excludeAccountId: selectedSourceAccount?.id,
                title: "Select Destination Account"
            )
        }
    }

    private func accountSelectorCard(
        title: String,
        account: Account?,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: account?.type.icon ?? icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(account?.displayColor ?? color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)

                    if let account = account {
                        Text(account.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appTextPrimary)

                        Text(account.formattedBalance)
                            .font(.system(size: 13))
                            .foregroundColor(account.isNegative ? .appDanger : .appTextSecondary)
                    } else {
                        Text("Select Account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Quick Amounts Section
    private var quickAmountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Amounts")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)

            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { quickAmount in
                    Button {
                        amount = String(format: "%.0f", quickAmount)
                    } label: {
                        Text(quickAmount.formattedAsCurrency())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appCardBackground)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Additional Details Section
    private var additionalDetailsSection: some View {
        VStack(spacing: 16) {
            // Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)

                TextField("Add a note...", text: $notes, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(2...4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Transfer Button
    private var transferButton: some View {
        Button {
            performTransfer()
        } label: {
            Text("Transfer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValid ? Color.appPrimary : Color.gray)
                .cornerRadius(Constants.Layout.buttonCornerRadius)
        }
        .disabled(!isValid)
    }

    // MARK: - Actions

    private func swapAccounts() {
        let temp = selectedSourceAccount
        selectedSourceAccount = selectedDestinationAccount
        selectedDestinationAccount = temp
    }

    private func performTransfer() {
        guard let source = selectedSourceAccount,
              let destination = selectedDestinationAccount,
              let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please fill in all fields correctly."
            showError = true
            return
        }

        do {
            try viewModel.transfer(
                from: source,
                to: destination,
                amount: amountValue,
                notes: notes.isEmpty ? nil : notes
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Account Picker View
struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]
    @Binding var selectedAccount: Account?
    let excludeAccountId: UUID?
    let title: String

    private var filteredAccounts: [Account] {
        accounts.filter { $0.id != excludeAccountId }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAccounts) { account in
                    Button {
                        selectedAccount = account
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(account.displayColor.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: account.type.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(account.displayColor)
                            }

                            // Account Info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)

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
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(account.isNegative ? .appDanger : .appTextPrimary)
                            }

                            // Selection indicator
                            if selectedAccount?.id == account.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appPrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TransferView()
}

#Preview("With Source Account") {
    TransferView(sourceAccount: Account.previewAccounts[0])
}
