//
//  SettingsViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - App Storage
    @AppStorage("appTheme") var appTheme: String = AppTheme.system.rawValue
    @AppStorage("currency") var currency: String = "USD"
    @AppStorage("currencySymbol") var currencySymbol: String = "$"

    // MARK: - Dependencies
    private let dataService: DataService

    // MARK: - Computed Properties
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: appTheme) ?? .system }
        set { appTheme = newValue.rawValue }
    }

    var currentCurrency: (code: String, symbol: String) {
        get { (currency, currencySymbol) }
        set {
            currency = newValue.code
            currencySymbol = newValue.symbol
        }
    }

    // Available currencies (FR-4.1)
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
    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }
}
