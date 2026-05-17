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
          SplashScreenView()
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

// MARK: - Splash Screen
struct SplashScreenView: View {
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        Image(systemName: "wallet.pass.fill")
          .font(.system(size: 72, weight: .medium))
          .foregroundStyle(.white)
          .scaleEffect(isAnimating ? 1.0 : 0.6)
          .opacity(isAnimating ? 1.0 : 0.0)

        VStack(spacing: 6) {
          Text("Expense Tracker")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.white)

          Text("Track your spending effortlessly")
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.8))
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 12)

        ProgressView()
          .progressViewStyle(.circular)
          .tint(.white)
          .padding(.top, 16)
          .opacity(isAnimating ? 0.8 : 0.0)
      }
      .animation(
        .spring(response: 0.6, dampingFraction: 0.7),
        value: isAnimating
      )
    }
    .onAppear { isAnimating = true }
  }
}
