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
    let account: Account?

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill((category?.swiftUIColor ?? .gray).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: category?.icon ?? "questionmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(category?.swiftUIColor ?? .gray)
            }

            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.payee ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 4) {
                    Text(category?.name ?? "Category")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)

                    if let account = account {
                        Text("•")
                            .foregroundColor(.appTextTertiary)
                        Text(account.name)
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.displayAmount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(transaction.amountColor)

                if transaction.isRecurring {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextTertiary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    let mockData = MockDataService.shared
    VStack(spacing: 0) {
        ForEach(mockData.transactions.prefix(3)) { transaction in
            TransactionRow(
                transaction: transaction,
                category: mockData.category(for: transaction.categoryId),
                account: mockData.account(for: transaction.accountId)
            )
            Divider()
                .padding(.leading, 56)
        }
    }
    .padding(.horizontal)
}
