# Design: Editable Profile + Email Verification

**Date:** 2026-05-02
**Status:** Approved
**Scope:** Two features built together — profile editing in Settings + email verification on sign-up

---

## Context

The app currently shows user info in Settings (avatar initials, name, email) but it's read-only. Users cannot update their profile after registration. Additionally, sign-up creates a Firebase account without email verification, allowing unverified users to access the app.

## Feature A: Editable Profile

### User Flow

1. User opens Settings → sees Account section with avatar, name, email
2. User taps Account section → EditProfileSheet opens (sheet over sheet)
3. Fields pre-filled: Full Name, Birth Date, Phone Number
4. Email shown read-only with lock icon
5. User edits fields → taps Save
6. Validation: name non-empty after trim, phone min 7 chars
7. On success: Firestore updated, local profile refreshed, sheet dismisses
8. SettingsView reflects updated name/email immediately

### Components

**New file: `Views/Settings/EditProfileSheet.swift`**
- NavigationStack with Cancel (top-left) and Save (top-right) buttons
- Form with: Full Name (text), Birth Date (DatePicker, max today), Phone (phone pad), Email (read-only, gray text, lock icon)
- Same validation as registration for editable fields
- `@ObservedObject var authViewModel: AuthViewModel`
- `@State` fields pre-populated from `authViewModel.currentUser`
- Save: calls `authViewModel.updateProfile()`

**Modified: `ViewModels/AuthViewModel.swift`**
- Add `updateProfile(name: String, phone: String, birthDate: Date)` method
- Validates inputs (name non-empty, phone min 7)
- Calls `authService.updateProfile(...)` — new protocol method
- On success: updates local `authState = .authenticated(updatedProfile)` to refresh UI immediately

**Modified: `Protocols/AuthServiceProtocol.swift`**
- Add `func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile`
- Add to MockAuthService for testing

**Modified: `Services/FirebaseAuthService.swift`**
- Implement `updateProfile()`:
  1. Get current user UID from `Auth.auth().currentUser`
  2. Create updated UserProfile (merge new fields, preserve uid/email/preferences/createdAt, set updatedAt = now)
  3. Save to Firestore `users/{uid}` via `setData(from:, merge: true)`
  4. Return updated profile

**Modified: `Views/Settings/SettingsView.swift`**
- Make Account section tappable (wrap in Button or add tap gesture)
- Add `@State private var showingEditProfile = false`
- Add `.sheet(isPresented: $showingEditProfile) { EditProfileSheet(authViewModel: authViewModel) }`

### Firestore Path

- Collection: `users`
- Document ID: Firebase Auth UID
- Fields updated: `fullName`, `phone`, `birthDate`, `updatedAt`
- Other fields (`uid`, `email`, `preferences`, `createdAt`) preserved via merge

---

## Feature B: Email Verification on Sign-Up

### User Flow

1. User fills sign-up form → taps Sign Up
2. Firebase Auth account created → Firestore profile saved → verification email sent
3. User is immediately signed out (not authenticated)
4. Alert appears: "Verification email sent to arpit@example.com. Please check your inbox and verify your email before signing in."
5. User taps OK → pops back to LoginView
6. User tries to login without verifying → error: "Please verify your email address before signing in."
7. User verifies email in their inbox → can now log in successfully
8. If user lost the email → taps "Resend Verification" on login screen → enters email → new verification email sent

### Components

**Modified: `Services/FirebaseAuthService.swift`**
- `register()`: after Firestore save, call `result.user.sendEmailVerification()` then `Auth.auth().signOut()` to immediately sign out the new user. The auth state listener fires with `unauthenticated`.
- `login()`: after sign-in, check `result.user.isEmailVerified`. If false, call `Auth.auth().signOut()` and throw `AppError.auth(.emailNotVerified)`.
- New method `sendEmailVerification(email: String, password: String) async throws`: temporarily signs in with email+password, calls `user.sendEmailVerification()`, then signs out. Firebase requires an authenticated user to send verification — this is the standard pattern.

**Modified: `ViewModels/AuthViewModel.swift`**
- `register()`: after successful register, instead of relying on auth state listener to navigate to MainTabView, the register method now needs to communicate "registration succeeded but verification needed" to the view.
- Add `@Published var registrationSucceeded = false` — set to true after register completes. RegisterView observes this to show the "verify your email" alert.
- After showing alert and user taps OK → navigate back to LoginView.

**Modified: `Views/Auth/RegisterView.swift`**
- Add `.onChange(of: authViewModel.registrationSucceeded)` → show alert
- Alert: "Verification Email Sent" with message about checking inbox
- On OK tap: set `authViewModel.registrationSucceeded = false` and call `onLoginTap?()` callback which sets `showRegister = false` in AuthGateView, popping back to LoginView

**Modified: `Views/Auth/LoginView.swift`**
- Add "Resend Verification Email" button below the Login button
- Tapping opens a sheet asking for email and password
- Submits via `authViewModel.sendEmailVerification(email:password:)`

**Modified: `ViewModels/AuthViewModel.swift`**
- Add `sendEmailVerification(email: String, password: String)` method
- Calls `authService.sendEmailVerification(email:password:)`

**Modified: `Protocols/AuthServiceProtocol.swift`**
- Add `func sendEmailVerification(email: String, password: String) async throws`
- Add to MockAuthService

**Modified: `Utils/AppError.swift`**
- Add `AuthError.emailNotVerified` case
- Message: "Please verify your email address before signing in. Check your inbox for the verification link."

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| User registers → email already verified (instant) | Firebase sends verification; user must click link regardless |
| User tries login without verifying | Blocked with "please verify" error |
| User didn't receive verification email | "Resend Verification" on login screen |
| Resend for non-existent email | Firebase auth error → "No account found" message |
| Resend for already-verified email | Firebase silently succeeds; user can now log in |
| User verifies email, then logs in | Normal login flow, `isEmailVerified = true` |
| User deletes account, re-registers same email | New verification email sent, must verify again |
| Email provider blocks Firebase emails | User stuck; show "Contact support" message |
| Firebase `sendEmailVerification` fails | Registration rollback (delete auth account), show error |

### Sign-Out After Register — Why

Firebase Auth auto-signs in after `createUser()`. The auth state listener would set `.authenticated` and navigate to MainTabView. We need to prevent this because:
1. The user hasn't verified their email yet
2. They should see the "verify your email" alert on RegisterView, not land on MainTabView

Solution: After sending verification email, immediately call `Auth.auth().signOut()`. The state listener fires with `.unauthenticated`. RegisterView is still visible, and we show the alert.

### Alert Sequence on Register

1. `register()` called → isLoading = true
2. FirebaseAuthService: createUser → save Firestore → sendEmailVerification → signOut
3. State listener fires: `.unauthenticated` (because we signed out)
4. AuthViewModel sets `registrationSucceeded = true`
5. RegisterView's `.onChange(of: registrationSucceeded)` fires
6. Alert: "Verification Email Sent — Please check your inbox..."
7. User taps OK → `authViewModel.registrationSucceeded = false` → navigate back to LoginView

---

## Files Changed

| File | Change |
|------|--------|
| `Protocols/AuthServiceProtocol.swift` | Add `updateProfile()`, `sendEmailVerification()`, update MockAuthService |
| `Services/FirebaseAuthService.swift` | Implement `updateProfile()`, `sendEmailVerification()`, modify `register()` to send verification + sign out, modify `login()` to check `isEmailVerified` |
| `Utils/AppError.swift` | Add `AuthError.emailNotVerified` |
| `ViewModels/AuthViewModel.swift` | Add `updateProfile()`, `sendEmailVerification()`, add `registrationSucceeded` published property, modify `register()` to set it |
| `Views/Auth/RegisterView.swift` | Add alert for "verification email sent" + navigate back to LoginView |
| `Views/Auth/LoginView.swift` | Add "Resend Verification Email" button + sheet |
| `Views/Settings/SettingsView.swift` | Make Account section tappable → open EditProfileSheet |
| `Views/Settings/EditProfileSheet.swift` | **NEW** — profile editing form |

---

## Verification

1. Build: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'`
2. Test profile editing: Settings → tap Account → edit name → Save → verify name updated
3. Test email verification: Register → verify alert shown → verify email sent → try login without verifying → blocked → verify email in inbox → login succeeds
4. Test resend: Login screen → "Resend Verification" → enter email + password → email resent
5. Test edge: edit profile with empty name → validation error shown
6. Test edge: try login unverified → error "Please verify your email"
