//
//  SettingsViewModelTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 25/04/26.
//

import XCTest
@testable import ExpenseTrackerApp

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private func makeViewModel() -> SettingsViewModel {
        let mockData = MockDataService()
        return SettingsViewModel(dataService: mockData)
    }

    // MARK: - Initial State

    func testDefaultThemeIsSystem() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.currentTheme, .system)
    }

    func testDefaultCurrencyIsUSD() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.currentCurrency.code, "USD")
        XCTAssertEqual(viewModel.currentCurrency.symbol, "$")
    }

    // MARK: - Theme Changes

    func testSetThemeToLight() {
        let viewModel = makeViewModel()
        viewModel.currentTheme = .light
        XCTAssertEqual(viewModel.currentTheme, .light)
    }

    func testSetThemeToDark() {
        let viewModel = makeViewModel()
        viewModel.currentTheme = .dark
        XCTAssertEqual(viewModel.currentTheme, .dark)
    }

    func testSetThemeBackToSystem() {
        let viewModel = makeViewModel()
        viewModel.currentTheme = .dark
        viewModel.currentTheme = .system
        XCTAssertEqual(viewModel.currentTheme, .system)
    }

    // MARK: - Currency Changes

    func testSetCurrency() {
        let viewModel = makeViewModel()
        viewModel.currentCurrency = (code: "EUR", symbol: "€")
        XCTAssertEqual(viewModel.currentCurrency.code, "EUR")
        XCTAssertEqual(viewModel.currentCurrency.symbol, "€")
    }

    func testSetCurrencyToINR() {
        let viewModel = makeViewModel()
        viewModel.currentCurrency = (code: "INR", symbol: "₹")
        XCTAssertEqual(viewModel.currentCurrency.code, "INR")
        XCTAssertEqual(viewModel.currentCurrency.symbol, "₹")
    }

    // MARK: - Available Currencies

    func testAvailableCurrenciesNotEmpty() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.availableCurrencies.isEmpty)
    }

    func testAvailableCurrenciesContainsUSD() {
        let viewModel = makeViewModel()
        let hasUSD = viewModel.availableCurrencies.contains { $0.code == "USD" }
        XCTAssertTrue(hasUSD)
    }

    func testAvailableCurrenciesContainsINR() {
        let viewModel = makeViewModel()
        let hasINR = viewModel.availableCurrencies.contains { $0.code == "INR" }
        XCTAssertTrue(hasINR)
    }

    func testAvailableCurrenciesHasAtLeast8Options() {
        let viewModel = makeViewModel()
        XCTAssertGreaterThanOrEqual(viewModel.availableCurrencies.count, 8)
    }

    // MARK: - AppTheme Enum

    func testAppThemeRawValues() {
        XCTAssertEqual(AppTheme.light.rawValue, "Light")
        XCTAssertEqual(AppTheme.dark.rawValue, "Dark")
        XCTAssertEqual(AppTheme.system.rawValue, "System")
    }

    func testAppThemeAllCases() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
    }
}
