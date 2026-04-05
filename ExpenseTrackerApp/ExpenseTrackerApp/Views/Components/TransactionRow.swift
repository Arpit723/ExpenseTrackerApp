//
//  TransactionRow.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let category: Category?

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon (FR-2.2)
            ZStack {
                Circle()
                    .fill((category?.swiftUIColor ?? .gray).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: category?.icon ?? "questionmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(category?.swiftUIColor ?? .gray)
            }

            // Transaction Details (FR-2.2: payee or category name, date)
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.payee ?? category?.name ?? "Transaction")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Text(transaction.date.relativeString)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            // Amount (FR-2.4: green for income, red for expense)
            Text(transaction.displayAmount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(transaction.amountColor)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    let dataService = DataService.shared
    VStack(spacing: 0) {
        ForEach(dataService.transactions.prefix(3)) { transaction in
            TransactionRow(
                transaction: transaction,
                category: dataService.category(for: transaction.categoryId)
            )
            Divider()
                .padding(.leading, 56)
        }
    }
    .padding(.horizontal)
}
