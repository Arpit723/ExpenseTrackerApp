//
//  CurrencyPickerView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Currency Picker View
struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    @State private var searchText: String = ""
    @State private var selectedCurrency: (code: String, symbol: String)

    // All available currencies with their details
    private let allCurrencies: [(code: String, symbol: String, name: String)] = [
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
        ("HKD", "$", "Hong Kong Dollar"),
        ("KRW", "₩", "South Korean Won"),
        ("BRL", "R$", "Brazilian Real"),
        ("RUB", "₽", "Russian Ruble"),
        ("ZAR", "R", "South African Rand"),
        ("SEK", "kr", "Swedish Krona"),
        ("NOK", "kr", "Norwegian Krone"),
        ("DKK", "kr", "Danish Krone"),
        ("NZD", "$", "New Zealand Dollar"),
        ("THB", "฿", "Thai Baht"),
        ("IDR", "Rp", "Indonesian Rupiah"),
        ("MYR", "RM", "Malaysian Ringgit"),
        ("PHP", "₱", "Philippine Peso"),
        ("TWD", "$", "Taiwan Dollar"),
        ("AED", "د.إ", "UAE Dirham"),
        ("SAR", "﷼", "Saudi Riyal"),
        ("ILS", "₪", "Israeli Shekel"),
        ("PLN", "zł", "Polish Zloty"),
        ("TRY", "₺", "Turkish Lira")
    ]

    private var filteredCurrencies: [(code: String, symbol: String, name: String)] {
        if searchText.isEmpty {
            return allCurrencies
        }

        return allCurrencies.filter { currency in
            currency.code.localizedCaseInsensitiveContains(searchText) ||
            currency.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        // Initialize with current currency
        _selectedCurrency = State(initialValue: ("USD", "$"))
    }

    var body: some View {
        NavigationStack {
            List {
                // Search bar
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appTextSecondary)

                        TextField("Search currencies...", text: $searchText)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                }

                // Popular currencies
                if searchText.isEmpty {
                    Section("Popular") {
                        ForEach(viewModel.availableCurrencies, id: \.code) { currency in
                            currencyRow(code: currency.code, symbol: currency.symbol, name: currency.name)
                        }
                    }
                }

                // All currencies
                Section(searchText.isEmpty ? "All Currencies" : "Results") {
                    ForEach(filteredCurrencies, id: \.code) { currency in
                        currencyRow(code: currency.code, symbol: currency.symbol, name: currency.name)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.currentCurrency = selectedCurrency
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedCurrency = viewModel.currentCurrency
            }
        }
    }

    private func currencyRow(code: String, symbol: String, name: String) -> some View {
        Button {
            selectedCurrency = (code, symbol)
        } label: {
            HStack(spacing: 12) {
                // Currency symbol badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 44, height: 32)

                    Text(symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appPrimary)
                }

                // Currency info
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Text(code)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                // Selection indicator
                if selectedCurrency.code == code {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    CurrencyPickerView()
}
