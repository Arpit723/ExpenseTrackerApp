# Profile Editing + Email Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add editable profile in Settings and email verification on sign-up so unverified users cannot log in.

**Architecture:** Extend AuthServiceProtocol with `updateProfile()` and `sendEmailVerification()`. FirebaseAuthService implements them using Firestore writes and Firebase Auth's `sendEmailVerification()`/`isEmailVerified`. AuthViewModel gains `updateProfile()`, `sendEmailVerification()`, and `registrationSucceeded` flag. Views add EditProfileSheet, verification alert on RegisterView, and resend button on LoginView.

**Tech Stack:** Swift, SwiftUI, Firebase Auth, Firebase Firestore, os.log

**Spec:** `docs/superpowers/specs/2026-05-02-profile-editing-email-verification-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `ExpenseTrackerApp/Utils/AppError.swift` | Modify | Add `AuthError.emailNotVerified` |
| `ExpenseTrackerApp/Protocols/AuthServiceProtocol.swift` | Modify | Add `updateProfile()`, `sendEmailVerification()` to protocol + MockAuthService |
| `ExpenseTrackerApp/Services/FirebaseAuthService.swift` | Modify | Implement `updateProfile()`, `sendEmailVerification()`, modify `register()` and `login()` |
| `ExpenseTrackerApp/ViewModels/AuthViewModel.swift` | Modify | Add `updateProfile()`, `sendEmailVerification()`, `registrationSucceeded`, modify `register()` |
| `ExpenseTrackerApp/Views/Auth/RegisterView.swift` | Modify | Add verification email sent alert + navigate back to LoginView |
| `ExpenseTrackerApp/Views/Auth/LoginView.swift` | Modify | Add "Resend Verification Email" button + sheet |
| `ExpenseTrackerApp/Views/Settings/SettingsView.swift` | Modify | Make Account section tappable → open EditProfileSheet |
| `ExpenseTrackerApp/Views/Settings/EditProfileSheet.swift` | Create | Profile editing form with validation |

---

### Task 1: Add `emailNotVerified` to AppError

**Files:**
- Modify: `ExpenseTrackerApp/Utils/AppError.swift`

- [ ] **Step 1: Add the new error case**

In `AuthError` enum (line 12-20), add `.emailNotVerified` after `.operationNotAllowed`:

```swift
enum AuthError: Equatable {
    case invalidCredentials
    case emailInUse
    case weakPassword
    case passwordMismatch
    case userNotFound
    case sessionExpired
    case operationNotAllowed
    case emailNotVerified
}
```

In `errorDescription` (after the `.operationNotAllowed` case at line 66):

```swift
        case .auth(.emailNotVerified):
            return "Please verify your email address before signing in. Check your inbox for the verification link."
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ExpenseTrackerApp/Utils/AppError.swift
git commit -m "feat: add emailNotVerified error case to AppError"
```

---

### Task 2: Extend AuthServiceProtocol + MockAuthService

**Files:**
- Modify: `ExpenseTrackerApp/Protocols/AuthServiceProtocol.swift`

- [ ] **Step 1: Add two new methods to the protocol**

Add after `func resetPassword(email: String) async throws` (line 27):

```swift
    func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile
    func sendEmailVerification(email: String, password: String) async throws
```

- [ ] **Step 2: Add implementations to MockAuthService (inside `#if DEBUG`)**

Add after `resetPassword` method (line 82) in MockAuthService:

```swift
    func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile {
        if shouldFail {
            throw AppError.data(.saveFailed)
        }
        let updated = UserProfile(
            fullName: name,
            phone: phone,
            birthDate: birthDate,
            preferences: UserPreferences()
        )
        authState = .authenticated(updated)
        authStateListener?(authState)
        return updated
    }

    func sendEmailVerification(email: String, password: String) async throws {
        if shouldFail {
            throw AppError.auth(.userNotFound)
        }
    }
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (FirebaseAuthService will fail — that's Task 3)

- [ ] **Step 4: Commit**

```bash
git add ExpenseTrackerApp/Protocols/AuthServiceProtocol.swift
git commit -m "feat: add updateProfile and sendEmailVerification to AuthServiceProtocol"
```

---

### Task 3: Implement FirebaseAuthService — updateProfile, sendEmailVerification, modify register/login

**Files:**
- Modify: `ExpenseTrackerApp/Services/FirebaseAuthService.swift`

- [ ] **Step 1: Add `updateProfile()` method**

Add after the `resetPassword()` method (after line 162):

```swift
    // MARK: - Update Profile
    func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile {
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("UpdateProfile: no current user")
            throw AppError.auth(.sessionExpired)
        }
        logger.info("UpdateProfile: updating profile for uid=\(currentUser.uid)")
        do {
            // Load existing profile to preserve fields
            let snapshot = try await Firestore.firestore().collection("users").document(currentUser.uid).getDocument()
            var existing = snapshot.exists ? (try? snapshot.data(as: UserProfile.self)) : nil

            let updated = UserProfile(
                id: existing?.id ?? UUID(),
                uid: currentUser.uid,
                email: currentUser.email,
                fullName: name,
                birthDate: birthDate,
                phone: phone,
                preferences: existing?.preferences ?? UserPreferences()
            )

            try Firestore.firestore().collection("users").document(currentUser.uid).setData(from: updated)
            logger.info("UpdateProfile: saved successfully")
            return updated
        } catch let error as AppError {
            throw error
        } catch {
            logger.error("UpdateProfile: failed — \(error.localizedDescription)")
            throw AppError.from(firebaseError: error)
        }
    }
```

- [ ] **Step 2: Add `sendEmailVerification()` method**

Add after `updateProfile()`:

```swift
    // MARK: - Send Email Verification
    func sendEmailVerification(email: String, password: String) async throws {
        logger.info("SendEmailVerification: signing in temporarily for email=\(email)")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            logger.info("SendEmailVerification: email sent, signing out")
            try Auth.auth().signOut()
        } catch {
            logger.error("SendEmailVerification: failed — \(error.localizedDescription)")
            throw AppError.from(firebaseError: error)
        }
    }
```

- [ ] **Step 3: Modify `register()` — send verification email + sign out**

Replace the existing `register()` method (lines 57-92). The key change: after Firestore save succeeds, send verification email then sign out immediately. Remove the `return profile` — instead, after sign-out, the state listener will fire `.unauthenticated`.

```swift
    // MARK: - Register
    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile {
        logger.info("Register: creating Firebase Auth user for email=\(email)")
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            logger.info("Register: auth user created uid=\(result.user.uid)")

            let profile = UserProfile(
                uid: result.user.uid,
                email: result.user.email,
                fullName: name,
                birthDate: birthDate,
                phone: phone,
                preferences: UserPreferences()
            )

            // Save profile to Firestore — must succeed for registration to complete
            do {
                logger.info("Register: saving profile to Firestore for uid=\(result.user.uid)")
                try Firestore.firestore().collection("users").document(result.user.uid).setData(from: profile)
                logger.info("Register: profile saved successfully")
            } catch {
                logger.error("Register: Firestore save failed — \(error.localizedDescription)")
                try? await result.user.delete()
                logger.info("Register: rolled back auth account due to Firestore failure")
                throw AppError.from(firebaseError: error)
            }

            // Send email verification
            do {
                logger.info("Register: sending verification email")
                try await result.user.sendEmailVerification()
                logger.info("Register: verification email sent")
            } catch {
                logger.error("Register: verification email failed — \(error.localizedDescription)")
                // Non-fatal: still sign out, user can resend later
            }

            // Sign out immediately — user must verify email before logging in
            try Auth.auth().signOut()
            logger.info("Register: signed out after registration")

            return profile
        } catch let error as AppError {
            throw error
        } catch {
            logger.error("Register: Firebase Auth error — \(error.localizedDescription)")
            throw AppError.from(firebaseError: error)
        }
    }
```

- [ ] **Step 4: Modify `login()` — check email verification**

Replace the existing `login()` method (lines 95-110):

```swift
    // MARK: - Login
    func login(email: String, password: String) async throws -> UserProfile {
        logger.info("Login: signing in email=\(email)")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            logger.info("Login: success uid=\(result.user.uid)")

            // Check email verification
            if !result.user.isEmailVerified {
                logger.warning("Login: email not verified for uid=\(result.user.uid)")
                try Auth.auth().signOut()
                throw AppError.auth(.emailNotVerified)
            }

            let profile = UserProfile(
                uid: result.user.uid,
                email: result.user.email,
                preferences: UserPreferences()
            )
            return profile
        } catch {
            logger.error("Login: failed — \(error.localizedDescription)")
            throw AppError.from(firebaseError: error)
        }
    }
```

**IMPORTANT:** `AppError.from(firebaseError:)` must handle `AppError.auth(.emailNotVerified)` correctly. Since `.emailNotVerified` is an `AppError` already (not a Firebase error), the catch block should re-throw it. The existing catch in `login()` catches all errors and calls `AppError.from(firebaseError:)`. But `AppError.auth(.emailNotVerified)` is already an AppError, not a Firebase error. Fix: add a `catch let error as AppError` before the generic catch:

```swift
        } catch let error as AppError {
            throw error
        } catch {
            logger.error("Login: failed — \(error.localizedDescription)")
            throw AppError.from(firebaseError: error)
        }
```

- [ ] **Step 5: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add ExpenseTrackerApp/Services/FirebaseAuthService.swift
git commit -m "feat: implement updateProfile, sendEmailVerification, and email verification on register/login"
```

---

### Task 4: Update AuthViewModel — add updateProfile, sendEmailVerification, registrationSucceeded

**Files:**
- Modify: `ExpenseTrackerApp/ViewModels/AuthViewModel.swift`

- [ ] **Step 1: Add `registrationSucceeded` published property**

Add after `@Published var isLoading: Bool = false` (line 16):

```swift
    @Published var registrationSucceeded: Bool = false
```

- [ ] **Step 2: Modify `register()` to set `registrationSucceeded`**

In the `register()` method, after `logger.info("Register: service call completed")` (line 89), add:

```swift
                self.registrationSucceeded = true
                self.isLoading = false
```

The register method's success path should now look like:

```swift
            do {
                _ = try await authService.register(
                    email: email,
                    password: password,
                    name: name,
                    birthDate: birthDate,
                    phone: phone
                )
                logger.info("Register: service call completed")
                self.registrationSucceeded = true
                self.isLoading = false
```

- [ ] **Step 3: Add `updateProfile()` method**

Add before the `// MARK: - Validation` section:

```swift
    // MARK: - Update Profile
    func updateProfile(name: String, phone: String, birthDate: Date) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            error = .validation(.emptyField("name"))
            return
        }
        guard phone.count >= 7 else {
            error = .validation(.invalidPhone)
            return
        }

        isLoading = true
        error = nil
        logger.info("UpdateProfile: starting")

        Task {
            do {
                let updated = try await authService.updateProfile(name: name, phone: phone, birthDate: birthDate)
                self.authState = .authenticated(updated)
                self.isLoading = false
                logger.info("UpdateProfile: success")
            } catch let err as AppError {
                logger.error("UpdateProfile: error — \(err.localizedDescription)")
                self.error = err
                self.isLoading = false
            } catch {
                logger.error("UpdateProfile: unknown error — \(error.localizedDescription)")
                self.error = .network(.serverError(error.localizedDescription))
                self.isLoading = false
            }
        }
    }
```

- [ ] **Step 4: Add `sendEmailVerification()` method**

Add after `updateProfile()`:

```swift
    // MARK: - Send Email Verification
    func sendEmailVerification(email: String, password: String) {
        isLoading = true
        error = nil
        logger.info("SendEmailVerification: starting for email=\(email)")

        Task {
            do {
                try await authService.sendEmailVerification(email: email, password: password)
                self.isLoading = false
                logger.info("SendEmailVerification: email sent")
            } catch let err as AppError {
                logger.error("SendEmailVerification: error — \(err.localizedDescription)")
                self.error = err
                self.isLoading = false
            } catch {
                logger.error("SendEmailVerification: unknown error — \(error.localizedDescription)")
                self.error = .network(.serverError(error.localizedDescription))
                self.isLoading = false
            }
        }
    }
```

- [ ] **Step 5: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add ExpenseTrackerApp/ViewModels/AuthViewModel.swift
git commit -m "feat: add updateProfile, sendEmailVerification, and registrationSucceeded to AuthViewModel"
```

---

### Task 5: Update RegisterView — verification email alert + navigate back

**Files:**
- Modify: `ExpenseTrackerApp/Views/Auth/RegisterView.swift`

- [ ] **Step 1: Add state for verification alert**

Add after `@State private var showConfirmPassword: Bool = false` (line 19):

```swift
    @State private var showVerificationAlert: Bool = false
```

- [ ] **Step 2: Add onChange and alert modifiers**

Add after the `.toolbar` block (after line 79, before the closing `}` of body):

```swift
        .onChange(of: authViewModel.registrationSucceeded) { _, succeeded in
            if succeeded {
                showVerificationAlert = true
            }
        }
        .alert("Verification Email Sent", isPresented: $showVerificationAlert) {
            Button("OK") {
                authViewModel.registrationSucceeded = false
                onLoginTap?()
            }
        } message: {
            Text("Please check your inbox and verify your email before signing in.")
        }
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ExpenseTrackerApp/Views/Auth/RegisterView.swift
git commit -m "feat: add email verification alert to RegisterView"
```

---

### Task 6: Update LoginView — resend verification button + sheet

**Files:**
- Modify: `ExpenseTrackerApp/Views/Auth/LoginView.swift`

- [ ] **Step 1: Add state variables**

Add after `@State private var showForgotPassword: Bool = false` (line 15):

```swift
    @State private var showResendVerification: Bool = false
    @State private var resendEmail: String = ""
    @State private var resendPassword: String = ""
```

- [ ] **Step 2: Add "Resend Verification" button**

Add after the `signUpLink` in the VStack (after line 49):

```swift
                // MARK: - Resend Verification
                resendVerificationButton
```

Add the computed property after the `signUpLink` computed property:

```swift
    // MARK: - Resend Verification
    private var resendVerificationButton: some View {
        Button(action: {
            resendEmail = email
            showResendVerification = true
        }) {
            Text("Resend Verification Email")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }
```

- [ ] **Step 3: Add the resend verification sheet**

Add after the `.sheet(isPresented: $showForgotPassword)` (after line 59):

```swift
        .sheet(isPresented: $showResendVerification) {
            resendVerificationSheet
        }
```

Add the sheet computed property after `forgotPasswordSheet`:

```swift
    // MARK: - Resend Verification Sheet
    private var resendVerificationSheet: some View {
        NavigationStack {
            VStack(spacing: Constants.Layout.spacing) {
                Text("Enter your email and password to resend the verification link.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.appTextTertiary)
                        .frame(width: 20)

                    TextField("Enter your email", text: $resendEmail)
                        .font(.system(size: 15))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundStyle(Color.appTextTertiary)
                        .frame(width: 20)

                    SecureField("Enter your password", text: $resendPassword)
                        .font(.system(size: 15))
                        .textContentType(.password)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))

                Button(action: {
                    authViewModel.sendEmailVerification(email: resendEmail, password: resendPassword)
                    showResendVerification = false
                }) {
                    Text("Resend Verification")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                }
                .disabled(resendEmail.trimmingCharacters(in: .whitespaces).isEmpty || !resendEmail.contains("@") || resendPassword.isEmpty)

                Spacer()
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 20)
            .background(Color.appBackground)
            .navigationTitle("Resend Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showResendVerification = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add ExpenseTrackerApp/Views/Auth/LoginView.swift
git commit -m "feat: add resend verification email button and sheet to LoginView"
```

---

### Task 7: Create EditProfileSheet

**Files:**
- Create: `ExpenseTrackerApp/Views/Settings/EditProfileSheet.swift`

- [ ] **Step 1: Create the file**

```swift
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
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ExpenseTrackerApp/Views/Settings/EditProfileSheet.swift
git commit -m "feat: create EditProfileSheet with name, phone, birthDate editing"
```

---

### Task 8: Update SettingsView — make Account section tappable

**Files:**
- Modify: `ExpenseTrackerApp/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add state for edit profile sheet**

Add after `@State private var showError = false` (line 18):

```swift
    @State private var showingEditProfile = false
```

- [ ] **Step 2: Wrap Account section content in a Button**

Replace the Account section HStack (lines 35-56) with a Button wrapper:

```swift
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
```

- [ ] **Step 3: Add the sheet modifier**

Add after the `.onChange(of: authViewModel.isAuthenticated)` modifier (after line 224):

```swift
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(authViewModel: authViewModel)
            }
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add ExpenseTrackerApp/Views/Settings/SettingsView.swift
git commit -m "feat: make SettingsView Account section tappable to open EditProfileSheet"
```

---

### Task 9: Final Build + Manual Verification

- [ ] **Step 1: Full clean build**

Run: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' clean build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -10`
Expected: All existing tests pass (new methods in MockAuthService keep mocks working)

- [ ] **Step 3: Manual verification checklist**

1. Settings → tap Account → EditProfileSheet opens → edit name → Save → name updated in Settings
2. Register → verification email sent → alert shown → tap OK → back to LoginView
3. Try login without verifying → error "Please verify your email address before signing in"
4. LoginView → "Resend Verification Email" → enter email + password → email resent
5. Edit profile with empty name → Save disabled (button grayed out)
6. Edit profile with short phone → Save disabled

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address issues found during manual verification"
```

---

## Self-Review Checklist

**Spec coverage:**
- Editable profile: Tasks 7, 8 (EditProfileSheet + SettingsView tappable)
- updateProfile protocol: Tasks 2, 3, 4
- Email verification on register: Task 3 (register), Task 5 (RegisterView alert)
- Block login if not verified: Task 3 (login check)
- Resend verification: Task 6 (LoginView button + sheet)
- emailNotVerified error: Task 1

**Placeholder scan:** No TBDs, TODOs, or "implement later" found.

**Type consistency:** `updateProfile(name:phone:birthDate:)` signature matches across protocol, FirebaseAuthService, and AuthViewModel. `sendEmailVerification(email:password:)` matches across all layers.
