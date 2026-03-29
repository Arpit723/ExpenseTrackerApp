//
//  EditProfileView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    // Form state
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var showingImagePicker = false
    @State private var showingSaveConfirmation = false
    @State private var hasChanges: Bool = false

    // Focus state
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, email
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Avatar Section
                avatarSection

                // MARK: - Personal Info Section
                personalInfoSection

                // MARK: - Account Info Section
                accountInfoSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingSaveConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges || displayName.isEmpty)
                }
            }
            .onAppear {
                loadProfileData()
            }
            .alert("Save Changes?", isPresented: $showingSaveConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Save") {
                    saveProfile()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Do you want to save them before leaving?")
            }
        }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        Section {
            VStack(spacing: 16) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        if let profile = viewModel.userProfile {
                            Text(profile.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    // Edit button
                    Button {
                        showingImagePicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.appCardBackground)
                                .frame(width: 32, height: 32)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .offset(x: 4, y: 4)
                }

                Text("Tap to change photo")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        Section("Personal Information") {
            // Display Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Display Name")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)

                TextField("Enter your name", text: $displayName)
                    .font(.system(size: 16))
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .email
                    }
                    .onChange(of: displayName) { _, _ in
                        checkForChanges()
                    }
            }
            .padding(.vertical, 4)

            // Email
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Address")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)

                TextField("Enter your email", text: $email)
                    .font(.system(size: 16))
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .onChange(of: email) { _, _ in
                        checkForChanges()
                    }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Account Info Section
    private var accountInfoSection: some View {
        Section("Account Information") {
            // Member Since
            HStack {
                Text("Member Since")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if let profile = viewModel.userProfile {
                    Text(profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
            }

            // Account ID
            HStack {
                Text("Account ID")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if let profile = viewModel.userProfile {
                    Text(profile.id.uuidString.prefix(8))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProfileData() {
        if let profile = viewModel.userProfile {
            displayName = profile.displayName
            email = profile.email
        }
    }

    private func checkForChanges() {
        guard let profile = viewModel.userProfile else {
            hasChanges = !displayName.isEmpty || !email.isEmpty
            return
        }

        hasChanges = displayName != profile.displayName || email != profile.email
    }

    private func saveProfile() {
        viewModel.updateProfile(
            name: displayName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces)
        )
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    EditProfileView()
}
