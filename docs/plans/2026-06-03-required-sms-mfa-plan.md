# Required SMS MFA Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Require every account to verify its university email and enroll an SMS second factor before accessing the marketplace.

**Architecture:** Existing layered UniSooq architecture with Riverpod

**Dependencies:** None

---

### Task 1: Restore Auth Gate Primitives

**Layer:** Presentation / Routing

**Files:**
- Modify: `lib/constants/app_routes.dart`
- Modify: `lib/router.dart`

**Implementation:**
- Restore the existing `AppRoutes.emailVerification` named route.
- Route unauthenticated users to `login`.
- Route signed-in users without `emailVerified` or without an enrolled second factor to the verification flow.
- Keep the verification route itself unguarded so it can serve both post-registration users and pending MFA sign-in challenges.

**Verification:**
- `flutter analyze lib/constants/app_routes.dart lib/router.dart`

### Task 2: Add Auth Service Support For Email Verification And MFA

**Layer:** Service

**Files:**
- Modify: `lib/services/auth_service.dart`

**Implementation:**
- Restore email-verification helper methods.
- Switch auth observation to support refreshed user state after `reload()`.
- Add helper methods for:
  - checking whether the current user has an enrolled second factor
  - starting SMS second-factor enrollment
  - finalizing SMS second-factor enrollment
  - starting an SMS challenge from `FirebaseAuthMultiFactorException`
  - resolving sign-in with the SMS assertion
- Normalize student phone numbers to E.164 for Jordan-compatible Firebase phone auth.

**Verification:**
- `flutter analyze lib/services/auth_service.dart`

### Task 3: Add Riverpod MFA Flow State

**Layer:** Provider

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Implementation:**
- Add a small MFA flow state object plus notifier to hold:
  - current flow mode
  - pending verification ID / resend token
  - pending sign-in resolver
  - masked phone display
  - error/loading state
- Update `authStateProvider` and `isAuthenticatedProvider` so the route guard reflects refreshed verification/MFA status.

**Verification:**
- `flutter analyze lib/providers/auth_provider.dart`

### Task 4: Rebuild The Verification Screen

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/auth/email_verification_screen.dart`

**Implementation:**
- Restore the screen as an interactive auth step instead of a legacy redirect.
- Support three states:
  - verify email
  - enroll SMS second factor
  - enter SMS code
- Support both post-registration enrollment and sign-in challenge resolution.
- Keep user-facing messaging friendly and avoid exposing raw Firebase errors.

**Verification:**
- `flutter analyze lib/screens/auth/email_verification_screen.dart`

### Task 5: Wire Login Into The Required Auth Flow

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/auth/login_screen.dart`

**Implementation:**
- After registration, navigate into the verification flow instead of `home`.
- After sign-in:
  - go to `home` only if email is verified and MFA is already enrolled
  - go to the verification flow if enrollment is still required
  - capture `FirebaseAuthMultiFactorException` and hand it to the MFA flow notifier before navigating to the verification screen

**Verification:**
- `flutter analyze lib/screens/auth/login_screen.dart`

### Task 6: Final Validation

**Layer:** Verification

**Files:**
- Modify as needed from previous tasks

**Implementation:**
- Format changed files.
- Run project verification commands.
- Report any Firebase-console prerequisites still needed:
  - Identity Platform enabled
  - SMS MFA enabled
  - Android SHA-256 configured
  - test phone numbers configured for development

**Verification:**
- `dart format lib/`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
