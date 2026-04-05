//
//  Constants.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

struct Constants {
    // MARK: - App Info
    static let appName = "Expense Tracker"
    static let appVersion = "2.0.0"
    static let appBuildNumber = "1"

    // MARK: - Currency
    static let defaultCurrency = "USD"
    static let defaultCurrencySymbol = "$"

    // MARK: - Quick Amount Buttons
    static let quickAmounts: [Double] = [5, 10, 20, 50, 100]

    // MARK: - Transaction Limits
    static let recentTransactionsCount = 10
    static let transactionsPerPage = 50

    // MARK: - Animation Durations
    struct Animation {
        static let `default`: Double = 0.3
        static let fast: Double = 0.15
        static let slow: Double = 0.5
        static let spring: Double = 0.6
    }

    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 10
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        static let padding: CGFloat = 20
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 32
    }

    // MARK: - Colors (Hex values)
    struct Colors {
        static let primary = "#007AFF"
        static let secondary = "#5856D6"
        static let success = "#34C759"
        static let warning = "#FF9500"
        static let danger = "#FF3B30"
        static let background = "#F2F2F7"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let transactionAdded = Notification.Name("transactionAdded")
    static let transactionUpdated = Notification.Name("transactionUpdated")
    static let transactionDeleted = Notification.Name("transactionDeleted")
}
