//
//  RecurringTransactionRow.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction
    let category: Category?

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill((category?.swiftUIColor ?? .gray).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: category?.icon ?? "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(category?.swiftUIColor ?? .gray)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 6) {
                    Label(recurring.frequency.rawValue, systemImage: recurring.frequency.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)

                    if recurring.autoCreate {
                        Text("Auto")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appSuccess.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Amount & Due Date
            VStack(alignment: .trailing, spacing: 4) {
                Text(recurring.formattedAmount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(recurring.isExpense ? .red : .green)

                Text(recurring.dueStatusText)
                    .font(.system(size: 11))
                    .foregroundColor(recurring.daysUntilDue <= 3 ? .orange : .appTextTertiary)
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
        ForEach(mockData.recurringTransactions.prefix(5)) { recurring in
            RecurringTransactionRow(
                recurring: recurring,
                category: mockData.category(for: recurring.categoryId)
            )
            Divider()
                .padding(.leading, 52)
        }
    }
    .padding(.horizontal)
}
