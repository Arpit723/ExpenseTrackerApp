//
//  SettingsView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct SettingsView: View {
  var dataService: any DataServiceProtocol
  @StateObject private var viewModel: SettingsViewModel
  @ObservedObject var authViewModel: AuthViewModel
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var currencyManager: CurrencyManager

  @State private var showLogoutConfirmation = false
  @State private var showDeleteConfirmation = false
  @State private var deleteConfirmationText = ""
  @State private var showError = false
  @State private var showingEditProfile = false
  @State private var showSettingsError = false

  init(
    dataService: any DataServiceProtocol, authViewModel: AuthViewModel,
    currencyManager: CurrencyManager
  ) {
    self.dataService = dataService
    _viewModel = StateObject(
      wrappedValue: SettingsViewModel(dataService: dataService, currencyManager: currencyManager))
    self._authViewModel = ObservedObject(wrappedValue: authViewModel)
  }

  private var userInitials: String {
    if let name = authViewModel.currentUser?.fullName, !name.isEmpty {
      return String(name.prefix(1)).uppercased()
    }
    if let email = authViewModel.currentUser?.email, !email.isEmpty {
      return String(email.prefix(1)).uppercased()
    }
    return "?"
  }

  var body: some View {
    NavigationStack {
      List {
        // MARK: - Account
        Section("Account") {
          Button(action: { showingEditProfile = true }) {
            HStack(spacing: 12) {
              Circle()
                .fill(Color.appPrimary)
                .frame(width: 44, height: 44)
                .overlay {
                  Text(userInitials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                }

              VStack(alignment: .leading, spacing: 2) {
                Text(authViewModel.currentUser?.fullName ?? "User")
                  .font(.system(size: 15, weight: .medium))
                  .foregroundStyle(Color.appTextPrimary)

                Text(authViewModel.currentUser?.email ?? "")
                  .font(.system(size: 13))
                  .foregroundStyle(Color.appTextSecondary)
              }

              Spacer()

              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.appTextTertiary)
            }
            .padding(.vertical, 4)
          }
        }

        // MARK: - Currency Selection (FR-4.1)
        Section("Currency") {
          Menu {
            ForEach(viewModel.availableCurrencies, id: \.code) { currency in
              Button(action: {
                viewModel.currentCurrency = (code: currency.code, symbol: currency.symbol)
              }) {
                HStack {
                  Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                  if viewModel.currentCurrency.code == currency.code {
                    Image(systemName: "checkmark")
                  }
                }
              }
            }
          } label: {
            HStack {
              Image(systemName: "dollarsign.circle")
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)

              Text("Currency")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextPrimary)

              Spacer()

              Text(viewModel.currentCurrency.code)
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)

              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.appTextTertiary)
            }
          }
        }

        // MARK: - Danger Zone
        Section {
          Button(action: { showLogoutConfirmation = true }) {
            HStack {
              if authViewModel.isLoading {
                ProgressView()
                  .frame(width: 24)
              } else {
                Image(systemName: "arrow.right.square")
                  .frame(width: 24)
              }

              Text("Sign Out")
                .font(.system(size: 15))
            }
            .foregroundStyle(Color.appDanger)
          }
          .disabled(authViewModel.isLoading)

          Button(action: { showDeleteConfirmation = true }) {
            HStack {
              Image(systemName: "trash")
                .frame(width: 24)

              Text("Delete Account")
                .font(.system(size: 15))
            }
            .foregroundStyle(Color.appDanger)
          }
          .disabled(authViewModel.isLoading)
        }

        // MARK: - Support
        Section {
          Button(action: {
            if let url = URL(string: "mailto:arpit_goal@yahoo.co.in") {
              UIApplication.shared.open(url)
            }
          }) {
            HStack {
              Image(systemName: "envelope.circle")
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)

              VStack(alignment: .leading, spacing: 2) {
                Text("Support")
                  .font(.system(size: 15))
                  .foregroundStyle(Color.appTextPrimary)

                Text("arpit_goal@yahoo.co.in")
                  .font(.system(size: 13))
                  .foregroundStyle(Color.appTextSecondary)
              }

              Spacer()

              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.appTextTertiary)
            }
          }
        }

        // MARK: - Version
        Section {
          HStack {
            Image(systemName: "info.circle")
              .foregroundStyle(Color.appPrimary)
              .frame(width: 24)

            Text("Version")
              .font(.system(size: 15))

            Spacer()

            Text("\(Constants.appVersion)")
              .font(.system(size: 15))
              .foregroundStyle(Color.appTextSecondary)
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .alert("Sign Out", isPresented: $showLogoutConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Sign Out", role: .destructive) {
          authViewModel.logout()
        }
      } message: {
        Text("Are you sure you want to sign out?")
      }
      .alert("Delete Account", isPresented: $showDeleteConfirmation) {
        TextField("Type DELETE to confirm", text: $deleteConfirmationText)
        Button("Cancel", role: .cancel) {
          deleteConfirmationText = ""
        }
        Button("Delete", role: .destructive) {
          authViewModel.deleteAccount()
          deleteConfirmationText = ""
        }
        .disabled(deleteConfirmationText != "DELETE")
      } message: {
        Text("This action is irreversible. All your data will be permanently deleted.")
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
      .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
        if !isAuth { dismiss() }
      }
      .onAppear { viewModel.syncFromFirestore() }
      .sheet(isPresented: $showingEditProfile) {
        EditProfileSheet(authViewModel: authViewModel)
      }
      .onChange(of: viewModel.error) { _, newValue in
        showSettingsError = newValue != nil
      }
      .alert(
        "Settings Error",
        isPresented: $showSettingsError,
        actions: {
          Button("OK") { viewModel.error = nil }
        },
        message: {
          Text(viewModel.error?.localizedDescription ?? "")
        }
      )
    }
  }
}

// MARK: - Preview
#Preview {
  SettingsView(
    dataService: DataService.shared,
    authViewModel: AuthViewModel(authService: LocalAuthService()),
    currencyManager: CurrencyManager()
  )
}
