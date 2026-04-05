//
//  CurrencyPickerView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    @State private var searchText: String = ""
    @State private var selectedCode: String = "USD"

    private var filteredCurrencies: [(code: String, symbol: String, name: String)] {
        if searchText.isEmpty {
            return viewModel.availableCurrencies
        }
        return viewModel.availableCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appTextTertiary)
                        TextField("Search currencies...", text: $searchText)
                            .font(.system(size: 15))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appTextTertiary)
                            }
                        }
                    }
                }

                Section("All Currencies") {
                    ForEach(filteredCurrencies, id: \.code) { currency in
                        Button {
                            selectedCode = currency.code
                            viewModel.currentCurrency = (code: currency.code, symbol: currency.symbol)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(currency.symbol)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 44, height: 32)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.name)
                                        .font(.system(size: 15))
                                        .foregroundColor(.appTextPrimary)
                                    Text(currency.code)
                                        .font(.system(size: 12))
                                        .foregroundColor(.appTextSecondary)
                                }

                                Spacer()

                                if selectedCode == currency.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.appPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                selectedCode = viewModel.currentCurrency.code
            }
        }
    }
}

#Preview {
    CurrencyPickerView()
}
