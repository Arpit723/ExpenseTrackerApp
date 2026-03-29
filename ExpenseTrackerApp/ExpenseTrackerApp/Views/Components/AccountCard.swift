//
//  AccountCard.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct AccountCard: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(account.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: account.type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(account.type.color)
            }

            // Account Info
            VStack(alignment: .leading, spacing: 4) {
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(account.isNegative ? .red : .appTextPrimary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Account Summary Card
struct AccountSummaryCard: View {
    let title: String
    let icon: String
    let total: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)

                Spacer()
            }

            Text(total.formattedAsCurrency())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(total < 0 ? .red : .appTextPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    let mockData = MockDataService.shared
    VStack(spacing: 12) {
        ForEach(mockData.accounts.prefix(4)) { account in
            AccountCard(account: account)
            Divider()
                .padding(.leading, 52)
        }
    }
    .padding()
    .background(Color.appBackground)
}
