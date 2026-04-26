//
//  ExpenseTrackerAppApp.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI
import FirebaseCore

@main
struct ExpenseTrackerAppApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let authService: any AuthServiceProtocol
        if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
            authService = FirebaseAuthService()
        } else {
            authService = LocalAuthService()
        }
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .authenticated:
                    MainTabView()
                        .environmentObject(dataService)
                case .unauthenticated, .loading:
                    AuthGateView(authViewModel: authViewModel)
                }
            }
            .animation(.easeInOut(duration: Constants.Animation.default), value: authViewModel.isAuthenticated)
        }
    }
}

// MARK: - Auth Gate (manages Login ↔ Register navigation)
struct AuthGateView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showRegister = false
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            LoginView(
                authViewModel: authViewModel,
                onSignUpTap: { showRegister = true }
            )
            .navigationDestination(isPresented: $showRegister) {
                RegisterView(
                    authViewModel: authViewModel,
                    onLoginTap: { showRegister = false }
                )
            }
        }
        .onChange(of: authViewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert(
            "Error",
            isPresented: $showError,
            actions: {
                Button("OK") { authViewModel.clearError() }
            },
            message: {
                Text(authViewModel.error?.localizedDescription ?? "")
            }
        )
    }
}
