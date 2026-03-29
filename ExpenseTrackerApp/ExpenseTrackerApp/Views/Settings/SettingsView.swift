//
//  SettingsView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Identifiable URL Wrapper
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    // Sheet states
    @State private var showingEditProfile = false
    @State private var showingCurrencyPicker = false
    @State private var showingThemeSelection = false
    @State private var showingFirstDayPicker = false
    @State private var showingExportSheet = false
    @State private var showingNotificationSettings = false
    @State private var exportedFileURL: IdentifiableURL?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                profileSection

                // MARK: - Preferences Section
                preferencesSection

                // MARK: - Notifications Section
                notificationsSection

                // MARK: - Security Section
                securitySection

                // MARK: - Support Section
                supportSection

                // MARK: - About Section
                aboutSection

                // MARK: - Danger Zone
                dangerZoneSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView()
            }
            .sheet(isPresented: $showingThemeSelection) {
                ThemeSelectionView()
            }
            .sheet(item: $exportedFileURL) { identifiableURL in
                ActivityViewController(activityItems: [identifiableURL.url])
            }
            .alert("Sign Out?", isPresented: $viewModel.showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out of your account?")
            }
            .alert("Delete Account?", isPresented: $viewModel.showingDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            Button {
                showingEditProfile = true
            } label: {
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        if let profile = viewModel.userProfile {
                            Text(profile.initials)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }

                    // Name and Email
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userProfile?.displayName ?? "User")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appTextPrimary)

                        Text(viewModel.userProfile?.email ?? "user@example.com")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
                .contentShape(Rectangle())
            }

            // Sign Out Button
            Button {
                viewModel.showingSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("Sign Out")
                        .font(.system(size: 15))
                        .foregroundColor(.appPrimary)
                }
            }
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section("Preferences") {
            // Currency
            Button {
                showingCurrencyPicker = true
            } label: {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("Currency")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    Text(viewModel.currentCurrency.code)
                        .font(.system(size: 15))
                        .foregroundColor(.appTextSecondary)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
            }

            // First Day of Week
            Button {
                showingFirstDayPicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("First Day of Week")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    Text(viewModel.isFirstDayMonday ? "Monday" : "Sunday")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextSecondary)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
            }

            // Theme
            Button {
                showingThemeSelection = true
            } label: {
                HStack {
                    Image(systemName: viewModel.currentTheme.icon)
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("Theme")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    Text(viewModel.currentTheme.rawValue)
                        .font(.system(size: 15))
                        .foregroundColor(.appTextSecondary)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
            }

            // Language
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.appPrimary)
                    .frame(width: 24)

                Text("Language")
                    .font(.system(size: 15))

                Spacer()

                Text("English")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)

                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextTertiary)
            }
        }
        .alert("First Day of Week", isPresented: $showingFirstDayPicker) {
            Button("Sunday") {
                viewModel.updateFirstDayOfWeek(false)
            }
            Button("Monday") {
                viewModel.updateFirstDayOfWeek(true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select the first day of the week for your calendar.")
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section("Notifications") {
            // Daily Reminder
            Toggle(isOn: Binding(
                get: { viewModel.dailyReminder },
                set: { newValue in
                    viewModel.dailyReminder = newValue
                    viewModel.updateNotificationSettings(viewModel.currentNotificationSettings)
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.appWarning)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(.system(size: 15))

                        Text("Get reminded to log expenses")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Budget Alerts
            Toggle(isOn: Binding(
                get: { viewModel.budgetAlerts },
                set: { newValue in
                    viewModel.budgetAlerts = newValue
                    viewModel.updateNotificationSettings(viewModel.currentNotificationSettings)
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.appDanger)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budget Alerts")
                            .font(.system(size: 15))

                        Text("Alert when approaching budget limits")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Bill Reminders
            Toggle(isOn: Binding(
                get: { viewModel.billReminders },
                set: { newValue in
                    viewModel.billReminders = newValue
                    viewModel.updateNotificationSettings(viewModel.currentNotificationSettings)
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bill Reminders")
                            .font(.system(size: 15))

                        Text("Remind about upcoming bills")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Weekly Summary
            Toggle(isOn: Binding(
                get: { viewModel.weeklySummary },
                set: { newValue in
                    viewModel.weeklySummary = newValue
                    viewModel.updateNotificationSettings(viewModel.currentNotificationSettings)
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.appSuccess)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Summary")
                            .font(.system(size: 15))

                        Text("Weekly spending overview")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Goal Achievements
            Toggle(isOn: Binding(
                get: { viewModel.goalAchievements },
                set: { newValue in
                    viewModel.goalAchievements = newValue
                    viewModel.updateNotificationSettings(viewModel.currentNotificationSettings)
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .foregroundColor(Color(hex: "#FFD700") ?? .yellow)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal Achievements")
                            .font(.system(size: 15))

                        Text("Celebrate when you reach goals")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Security Section
    private var securitySection: some View {
        Section("Security") {
            // Face ID / Touch ID
            Toggle(isOn: Binding(
                get: { viewModel.biometricEnabled },
                set: { viewModel.biometricEnabled = $0 }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Face ID / Touch ID")
                            .font(.system(size: 15))

                        Text("Use biometrics to unlock app")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }

            // Passcode
            Button {
                // Change passcode
            } label: {
                HStack {
                    Image(systemName: "lock.circle")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("Change Passcode")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
            }
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        Section("Support") {
            // Help Center
            settingsRow(icon: "questionmark.circle", title: "Help Center") {
                // Open help center
            }

            // Contact Us
            settingsRow(icon: "envelope", title: "Contact Us") {
                viewModel.openEmail()
            }

            // Feature Requests
            settingsRow(icon: "lightbulb", title: "Feature Requests") {
                // Open feature requests
            }

            // Rate App
            settingsRow(icon: "star.fill", iconColor: .appWarning, title: "Rate the App") {
                viewModel.rateApp()
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        Section("About") {
            // Privacy Policy
            settingsRow(icon: "hand.raised", title: "Privacy Policy") {
                // Open privacy policy
            }

            // Terms of Service
            settingsRow(icon: "doc.text", title: "Terms of Service") {
                // Open terms
            }

            // Version
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.appPrimary)
                    .frame(width: 24)

                Text("Version")
                    .font(.system(size: 15))

                Spacer()

                Text("\(Constants.appVersion) (\(Constants.appBuildNumber))")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        Section("Danger Zone") {
            // Export Data
            Button {
                if let url = viewModel.exportData() {
                    exportedFileURL = IdentifiableURL(url: url)
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.appPrimary)
                        .frame(width: 24)

                    Text("Export Data")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)
                }
            }

            // Delete Account
            Button {
                viewModel.showingDeleteAccountConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)

                    Text("Delete Account")
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Helper
    private func settingsRow(icon: String, iconColor: Color = .appPrimary, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextTertiary)
            }
        }
    }
}

// MARK: - Activity View Controller (for sharing)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    SettingsView()
}
