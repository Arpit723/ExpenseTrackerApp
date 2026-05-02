//
//  EditProfileSheet.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 02/05/26.
//

import SwiftUI

struct EditProfileSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var birthDate: Date = Date()
    @State private var phoneNumber: String = ""

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        && phoneNumber.count >= 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Layout.spacing) {
                    // Full Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)

                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .foregroundStyle(Color.appTextTertiary)
                                .frame(width: 20)

                            TextField("Enter your full name", text: $fullName)
                                .font(.system(size: 15))
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                    }

                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birth Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)

                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.appTextTertiary)
                                .frame(width: 20)

                            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()

                            Spacer()
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                    }

                    // Phone Number
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)

                        HStack(spacing: 12) {
                            Image(systemName: "phone")
                                .foregroundStyle(Color.appTextTertiary)
                                .frame(width: 20)

                            TextField("Enter your phone number", text: $phoneNumber)
                                .font(.system(size: 15))
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                    }

                    // Email (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)

                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundStyle(Color.appTextTertiary)
                                .frame(width: 20)

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.appTextTertiary)

                            Spacer()

                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                    }

                    // Save Button
                    Button(action: saveProfile) {
                        HStack(spacing: 8) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(authViewModel.isLoading ? "Saving..." : "Save Changes")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: isFormValid
                                    ? [Color.appPrimary, Color.appSecondary]
                                    : [Color.gray, Color.gray]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, Constants.Layout.padding)
                .padding(.top, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    fullName = user.fullName ?? ""
                    birthDate = user.birthDate ?? Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
                    phoneNumber = user.phone ?? ""
                }
            }
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { authViewModel.error != nil },
                    set: { if !$0 { authViewModel.clearError() } }
                ),
                actions: {
                    Button("OK") { authViewModel.clearError() }
                },
                message: {
                    Text(authViewModel.error?.localizedDescription ?? "")
                }
            )
        }
    }

    private func saveProfile() {
        authViewModel.updateProfile(name: fullName, phone: phoneNumber, birthDate: birthDate)
        if authViewModel.error == nil {
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    EditProfileSheet(authViewModel: AuthViewModel(authService: LocalAuthService()))
}
