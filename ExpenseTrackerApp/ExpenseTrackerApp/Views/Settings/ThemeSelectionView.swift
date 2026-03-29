//
//  ThemeSelectionView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTheme: AppTheme

    init() {
        _selectedTheme = State(initialValue: .system)
    }

    var body: some View {
        NavigationStack {
            List {
                // Theme Options
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        themeOptionRow(theme)
                    }
                } footer: {
                    Text("System automatically switches between Light and Dark modes based on your device settings.")
                }

                // Preview Section
                Section("Preview") {
                    themePreviewCard
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.currentTheme = selectedTheme
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedTheme = viewModel.currentTheme
            }
        }
    }

    // MARK: - Theme Option Row
    private func themeOptionRow(_ theme: AppTheme) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTheme = theme
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme == selectedTheme ? Color.appPrimary : Color.appPrimary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: theme.icon)
                        .font(.system(size: 20))
                        .foregroundColor(theme == selectedTheme ? .white : .appPrimary)
                }

                // Title and Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextPrimary)

                    Text(themeDescription(for: theme))
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                // Selection indicator
                if theme == selectedTheme {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        case .system:
            return "Follow system appearance"
        }
    }

    // MARK: - Theme Preview Card
    private var themePreviewCard: some View {
        VStack(spacing: 16) {
            // Mock header
            HStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.3))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appTextPrimary.opacity(0.6))
                        .frame(width: 80, height: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appTextSecondary.opacity(0.4))
                        .frame(width: 50, height: 8)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appPrimary)
                    .frame(width: 40, height: 20)
            }

            // Mock balance card
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appTextSecondary.opacity(0.4))
                    .frame(width: 100, height: 12)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appTextPrimary)
                    .frame(width: 150, height: 24)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appSuccess.opacity(0.3))
                    .frame(height: 8)
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(12)

            // Mock transaction rows
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.2))
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appTextPrimary.opacity(0.6))
                                .frame(width: 80, height: 10)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appTextSecondary.opacity(0.4))
                                .frame(width: 60, height: 8)
                        }

                        Spacer()

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appDanger.opacity(0.8))
                            .frame(width: 50, height: 12)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appBackground)
        .cornerRadius(12)
    }
}

// MARK: - Color Scheme Extension
extension ColorScheme {
    var themeName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Preview
#Preview {
    ThemeSelectionView()
}
