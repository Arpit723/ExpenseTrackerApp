//
//  SettingsViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showingError: Bool = false
    @Published var showingSignOutConfirmation: Bool = false
    @Published var showingDeleteAccountConfirmation: Bool = false

    // App Storage for persistent settings
    @AppStorage("appTheme") var appTheme: String = AppTheme.system.rawValue
    @AppStorage("currency") var currency: String = "USD"
    @AppStorage("currencySymbol") var currencySymbol: String = "$"
    @AppStorage("firstDayOfWeek") var firstDayOfWeek: Int = 2  // Monday
    @AppStorage("biometricEnabled") var biometricEnabled: Bool = true
    @AppStorage("notifications_dailyReminder") var dailyReminder: Bool = true
    @AppStorage("notifications_budgetAlerts") var budgetAlerts: Bool = true
    @AppStorage("notifications_billReminders") var billReminders: Bool = true
    @AppStorage("notifications_weeklySummary") var weeklySummary: Bool = true
    @AppStorage("notifications_goalAchievements") var goalAchievements: Bool = true

    // Dependencies
    private let dataService: MockDataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: appTheme) ?? .system }
        set {
            appTheme = newValue.rawValue
            applyTheme(newValue)
        }
    }

    var currentCurrency: (code: String, symbol: String) {
        get { (currency, currencySymbol) }
        set {
            currency = newValue.code
            currencySymbol = newValue.symbol
            updateProfileCurrency()
        }
    }

    var isFirstDayMonday: Bool {
        get { firstDayOfWeek == 2 }
        set { firstDayOfWeek = newValue ? 2 : 1 }
    }

    // Available currencies
    let availableCurrencies: [(code: String, symbol: String, name: String)] = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "$", "Canadian Dollar"),
        ("AUD", "$", "Australian Dollar"),
        ("INR", "₹", "Indian Rupee"),
        ("CNY", "¥", "Chinese Yuan"),
        ("CHF", "CHF", "Swiss Franc"),
        ("MXN", "$", "Mexican Peso"),
        ("SGD", "$", "Singapore Dollar"),
        ("HKD", "$", "Hong Kong Dollar")
    ]

    // MARK: - Initialization
    init(dataService: MockDataService = .shared) {
        self.dataService = dataService
        loadUserProfile()
    }

    // MARK: - Load User Profile
    func loadUserProfile() {
        userProfile = dataService.userProfile
    }

    // MARK: - Update Profile
    func updateProfile(name: String, email: String) {
        guard var profile = userProfile else { return }

        profile.displayName = name
        profile.email = email
        profile.updatedAt = Date()

        dataService.userProfile = profile
        userProfile = profile

        // Post notification for other views
        NotificationCenter.default.post(name: .userProfileUpdated, object: profile)
    }

    // MARK: - Theme Management
    func applyTheme(_ theme: AppTheme) {
        // The actual theme application is handled by SwiftUI
        // This is a hook for any additional theme setup
        updateProfileTheme()
    }

    private func updateProfileTheme() {
        guard var profile = userProfile else { return }
        profile.preferences.theme = currentTheme
        profile.updatedAt = Date()
        dataService.userProfile = profile
        userProfile = profile
    }

    // MARK: - Currency Management
    private func updateProfileCurrency() {
        guard var profile = userProfile else { return }
        profile.preferences.currency = currency
        profile.preferences.currencySymbol = currencySymbol
        profile.updatedAt = Date()
        dataService.userProfile = profile
        userProfile = profile

        // Post notification for other views to update
        NotificationCenter.default.post(name: .currencyChanged, object: nil)
    }

    // MARK: - First Day of Week
    func updateFirstDayOfWeek(_ isMonday: Bool) {
        isFirstDayMonday = isMonday
        guard var profile = userProfile else { return }
        profile.preferences.firstDayOfWeek = isMonday ? 2 : 1
        profile.updatedAt = Date()
        dataService.userProfile = profile
        userProfile = profile
    }

    // MARK: - Notifications
    func updateNotificationSettings(_ settings: NotificationSettings) {
        dailyReminder = settings.dailyReminder
        budgetAlerts = settings.budgetAlerts
        billReminders = settings.billReminders
        weeklySummary = settings.weeklySummary
        goalAchievements = settings.goalAchievements

        guard var profile = userProfile else { return }
        profile.preferences.notifications = settings
        profile.updatedAt = Date()
        dataService.userProfile = profile
        userProfile = profile
    }

    var currentNotificationSettings: NotificationSettings {
        NotificationSettings(
            dailyReminder: dailyReminder,
            budgetAlerts: budgetAlerts,
            billReminders: billReminders,
            weeklySummary: weeklySummary,
            goalAchievements: goalAchievements,
            newFeatures: false
        )
    }

    // MARK: - Authentication
    func signOut() async {
        isLoading = true
        // Simulate sign out process
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Firebase sign out will be added later
        isLoading = false

        // Reset user data (for now, until Firebase)
        NotificationCenter.default.post(name: .userSignedOut, object: nil)
    }

    func deleteAccount() async {
        isLoading = true
        // Simulate account deletion
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Firebase account deletion will be added later

        // Clear all data
        dataService.userProfile = nil
        dataService.accounts.removeAll()
        dataService.transactions.removeAll()
        dataService.budgets.removeAll()
        dataService.goals.removeAll()

        isLoading = false

        NotificationCenter.default.post(name: .userAccountDeleted, object: nil)
    }

    // MARK: - Export Data
    func exportData() -> URL? {
        // Create CSV export of all data
        var csvContent = "Expense Tracker Data Export\n"
        csvContent += "Exported: \(Date().formatted(date: .complete, time: .standard))\n\n"

        // Export accounts
        csvContent += "=== ACCOUNTS ===\n"
        csvContent += "Name,Type,Balance,Institution\n"
        for account in dataService.accounts {
            csvContent += "\(account.name),\(account.type.rawValue),\(account.balance),\(account.institution ?? "")\n"
        }

        // Export transactions
        csvContent += "\n=== TRANSACTIONS ===\n"
        csvContent += "Date,Payee,Amount,Category,Notes\n"
        for transaction in dataService.transactions.sorted(by: { $0.date > $1.date }) {
            let category = dataService.category(for: transaction.categoryId)?.name ?? ""
            let payee = transaction.payee ?? ""
            let notes = transaction.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            csvContent += "\(transaction.date.formatted(date: .abbreviated, time: .omitted)),\(payee),\(transaction.amount),\(category),\(notes)\n"
        }

        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("expense_tracker_export_\(Date().timeIntervalSince1970).csv")

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            self.error = error
            self.showingError = true
            return nil
        }
    }

    // MARK: - Rate App
    func rateApp() {
        // Open App Store review prompt
        // In production, use SKStoreReviewController.requestReview()
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Contact & Support
    func openEmail() {
        let email = "support@expensetracker.app"
        let subject = "Expense Tracker Support"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    static let currencyChanged = Notification.Name("currencyChanged")
    static let themeChanged = Notification.Name("themeChanged")
    static let userSignedOut = Notification.Name("userSignedOut")
    static let userAccountDeleted = Notification.Name("userAccountDeleted")
}
