//
//  SettingsView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Currency Selection (FR-4.1)
                Section("Currency") {
                    Menu {
                        ForEach(viewModel.availableCurrencies, id: \.code) { currency in
                            Button(action: {
                                viewModel.currentCurrency = (code: currency.code, symbol: currency.symbol)
                            }) {
                                HStack {
                                    Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                                    if viewModel.currentCurrency.code == currency.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
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
                                .font(.system(size: 12))
                                .foregroundColor(.appTextTertiary)
                        }
                    }
                }

                // MARK: - Theme Selection (FR-4.2)
                Section("Theme") {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            viewModel.currentTheme = theme
                        }) {
                            HStack {
                                Image(systemName: theme.icon)
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.rawValue)
                                        .font(.system(size: 15))
                                        .foregroundColor(.appTextPrimary)

                                    Text(themeDescription(for: theme))
                                        .font(.system(size: 12))
                                        .foregroundColor(.appTextSecondary)
                                }

                                Spacer()

                                if viewModel.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appPrimary)
                                }
                            }
                        }
                    }
                }

                // MARK: - Version
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.appPrimary)
                            .frame(width: 24)

                        Text("Version")
                            .font(.system(size: 15))

                        Spacer()

                        Text("\(Constants.appVersion)")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
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

// MARK: - Preview
#Preview {
    SettingsView()
}
