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
    @State private var showingSettings = false

    enum Tab: Int, CaseIterable {
        case dashboard = 0
        case transactions = 1

        var title: String {
            switch self {
            case .dashboard: return "Home"
            case .transactions: return "Transactions"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .transactions: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Tab Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .transactions:
                    TransactionsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Custom Tab Bar
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        TabBarButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }

                    // Settings button
                    TabBarButton(
                        icon: "gearshape.fill",
                        title: "Settings",
                        isSelected: false,
                        action: { showingSettings = true }
                    )
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
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTabView.Tab?
    let icon: String
    let title: String
    var isSelected: Bool = false
    let action: () -> Void

    init(tab: MainTabView.Tab, isSelected: Bool, action: @escaping () -> Void) {
        self.tab = tab
        self.icon = tab.icon
        self.title = tab.title
        self.isSelected = isSelected
        self.action = action
    }

    init(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.tab = nil
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appPrimary : .appTextTertiary)
                    .frame(height: 24)

                Text(title)
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
