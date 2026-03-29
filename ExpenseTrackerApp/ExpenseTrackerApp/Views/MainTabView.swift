//
//  MainTabView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var showingAddTransaction = false

    enum Tab: Int, CaseIterable {
        case dashboard = 0
        case transactions = 1
        case budget = 2
        case accounts = 3
        case settings = 4

        var title: String {
            switch self {
            case .dashboard: return "Home"
            case .transactions: return "Transactions"
            case .budget: return "Budget"
            case .accounts: return "Accounts"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .transactions: return "list.bullet.rectangle"
            case .budget: return "chart.pie.fill"
            case .accounts: return "creditcard.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var selectedIcon: String {
            return icon
        }
    }

    // MARK: - Tab Navigation Helper
    private func navigateToTab(_ tab: Tab) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = tab
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Tab Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(onNavigateToTab: navigateToTab)
                case .transactions:
                    TransactionsView()
                case .budget:
                    BudgetView()
                case .accounts:
                    AccountsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Custom Tab Bar
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        if tab.rawValue == 2 {
                            // Center FAB space
                            Spacer()
                        }

                        TabBarButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )

                        if tab.rawValue == 2 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(Color.appCardBackground)
            }

            // MARK: - Floating Add Button
            FloatingAddButton(action: { showingAddTransaction = true })
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 70)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTabView.Tab
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appPrimary : .appTextTertiary)
                    .frame(height: 24)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appPrimary : .appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
