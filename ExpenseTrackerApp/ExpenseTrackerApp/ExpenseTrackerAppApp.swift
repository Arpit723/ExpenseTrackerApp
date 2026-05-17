//
//  ExpenseTrackerAppApp.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import FirebaseCore
import SwiftUI

@main
struct ExpenseTrackerAppApp: App {
  @StateObject private var dataServiceContainer = DataServiceContainer()
  @StateObject private var authViewModel: AuthViewModel
  @StateObject private var currencyManager = CurrencyManager()

  private var hasFirebaseConfig: Bool {
    Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
  }

  init() {
    let authService: any AuthServiceProtocol
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
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
            .environmentObject(dataServiceContainer)
            .environmentObject(authViewModel)
            .environmentObject(currencyManager)
            .task {
              guard hasFirebaseConfig else { return }
              dataServiceContainer.switchToFirestore(uid: authViewModel.currentUser?.uid ?? "")
              let migration = FirestoreMigration(uid: authViewModel.currentUser?.uid ?? "")
              try? await migration.migrateIfNeeded()
              do {
                try await dataServiceContainer.service.loadData()
              } catch {
                // Firestore data load failed; offline cache may still serve data
              }
            }
        case .unauthenticated:
          AuthGateView(authViewModel: authViewModel)
            .onAppear { dataServiceContainer.switchToLocal() }
        case .loading:
          AuthGateView(authViewModel: authViewModel)
        }
      }
      .animation(
        .easeInOut(duration: Constants.Animation.default), value: authViewModel.isAuthenticated
      )
      .preferredColorScheme(.light)
    }
  }
}

// MARK: - Auth Gate (manages Login <-> Register navigation)
struct AuthGateView: View {
  @ObservedObject var authViewModel: AuthViewModel
  @State private var showRegister = false
  @State private var showError: Bool = false
  @State private var showVerificationAlert: Bool = false

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
    .onChange(of: authViewModel.registrationSucceeded) { _, succeeded in
      if succeeded {
        showVerificationAlert = true
      }
    }
    .alert("Verification Email Sent", isPresented: $showVerificationAlert) {
      Button("OK") {
        authViewModel.registrationSucceeded = false
        showRegister = false
      }
    } message: {
      Text("Please check your inbox and verify your email before signing in.")
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
