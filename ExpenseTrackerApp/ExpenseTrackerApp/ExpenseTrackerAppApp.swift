//
//  ExpenseTrackerAppApp.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

@main
struct ExpenseTrackerAppApp: App {
    @StateObject private var dataService = DataService.shared
    @State private var isAuthenticated: Bool = false

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
                    .environmentObject(dataService)
            } else {
                AuthGateView(onLoginSuccess: { isAuthenticated = true })
            }
        }
    }
}

// MARK: - Auth Gate (manages Login ↔ Register navigation)
struct AuthGateView: View {
    let onLoginSuccess: () -> Void
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            LoginView(
                onSignUpTap: { showRegister = true },
                onLoginSuccess: onLoginSuccess
            )
            .navigationDestination(isPresented: $showRegister) {
                RegisterView(
                    onLoginTap: { showRegister = false },
                    onRegisterSuccess: onLoginSuccess
                )
            }
        }
    }
}
