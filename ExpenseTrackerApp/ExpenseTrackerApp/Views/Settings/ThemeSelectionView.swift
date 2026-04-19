//
//  ThemeSelectionView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTheme: AppTheme = .system

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            selectedTheme = theme
                            viewModel.currentTheme = theme
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme == selectedTheme ? Color.appPrimary : Color.appPrimary.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: theme.icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(theme == selectedTheme ? .white : Color.appPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.appTextPrimary)

                                    Text(themeDescription(for: theme))
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.appTextSecondary)
                                }

                                Spacer()

                                if theme == selectedTheme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                    }
                } footer: {
                    Text("System automatically switches between Light and Dark modes based on your device settings.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                selectedTheme = viewModel.currentTheme
            }
        }
    }

    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        case .system: return "Follow system appearance"
        }
    }
}

#Preview {
    ThemeSelectionView()
}
