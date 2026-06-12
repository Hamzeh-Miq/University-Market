# UniSooq Project Review

Date: 2026-05-23

Review workflow used: `start-flutter-craft`, `flutter-review-request`, and `flutter-verification`.

## Scope

This review covered:

- Project structure under `lib/`, `test/`, and root Firebase/security files
- Architecture compliance against `AGENTS.md`
- Firebase/Auth/Firestore safety and access control
- Design-system consistency
- Routing, test coverage, and project readiness signals

## Verification Status

The required Flutter verification commands could not run in this shell because the Flutter SDK is not available on `PATH`.

Attempted commands:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

Observed result for each command:

```text
flutter : The term 'flutter' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

Because of that, this review is based on static code inspection plus rule-by-rule comparison with `AGENTS.md`, not on successful analyzer/test/build evidence.

## Findings

### 1. Critical: `users/{uid}` rules allow self-escalation and unrestricted self-mutation

Files:

- `firestore.rules:15-24`

Problem:

- `allow write: if request.auth.uid == userId;` lets any authenticated user rewrite their entire user document.
- That means a user can change privileged fields such as `role`, `isSubscribed`, `subscriptionExpiresAt`, `rating`, `reviewCount`, or any future admin-only fields.
- The narrower `allow update` rule for `rating`/`reviewCount` is effectively undermined by the broader owner write rule above it.

Why this matters:

- A normal user can promote themselves to admin.
- A user can grant themselves a subscription without approval.
- Reputation fields can be tampered with client-side.

Needed modification:

- Replace broad owner `write` access with field-level rules.
- Allow owners to update only safe profile fields.
- Restrict `role`, subscription fields, moderation fields, and aggregates to admin-only or server-side writes.

### 2. Critical: the payment flow grants subscriptions directly from the client

Files:

- `lib/screens/subscription/payment_screen.dart:82-97`
- `lib/services/user_service.dart:67-95`
- `firestore.rules:17-18`

Problem:

- The payment screen simulates a delay and then calls `UserService().activateSubscription(uid)` directly.
- There is no verified backend payment step, no server authority, and the current Firestore rules allow the user document update.

Why this matters:

- Any signed-in user can unlock paid access from the client.
- This is both a business-logic vulnerability and a security-model failure.

Needed modification:

- Remove direct subscription activation from the client.
- Route subscription activation through an admin-only flow or trusted backend function.
- Lock `isSubscribed`, `subscriptionActivatedAt`, and `subscriptionExpiresAt` in Firestore rules.

### 3. High: email-domain policy is inconsistent across auth, docs, UI, and security rules

Files:

- `AGENTS.md` section 1 and section 7
- `lib/services/auth_service.dart:10-13, 40-57`
- `lib/screens/auth/login_screen.dart:310-319`
- `lib/screens/auth/email_verification_screen.dart:9, 132`
- `lib/screens/auth/welcome_screen.dart:188-191`
- `firestore.rules:9-12`

Problem:

- `AGENTS.md` says access is restricted to `@students.edu.jo`.
- App screens also tell users the app is for `@students.edu.jo`.
- `AuthService` actually accepts `@asu.edu.jo`.
- Admin assignment checks `202120554@students.asu.edu.jo`, which is a third format.
- Firestore rules accept any verified `.edu` address, which is broader than both policy variants.

Why this matters:

- Users can be blocked or accepted inconsistently depending on where validation happens.
- Security rules do not match product policy.
- Support/debugging gets much harder because the source of truth is unclear.

Needed modification:

- Pick one authoritative domain policy.
- Apply it consistently in `AuthService`, UI copy, docs, and Firestore rules.
- Move any admin-identification logic away from hardcoded email strings when possible.

### 4. High: the service -> provider -> UI architecture is being bypassed in multiple places

Files:

- `lib/providers/auth_provider.dart:9-10, 33, 49`
- `lib/screens/chat/chat_detail_screen.dart:183-187`
- `lib/screens/auth/login_screen.dart:25`
- `lib/screens/auth/email_verification_screen.dart:22`
- `lib/screens/listing/add_listing_screen.dart:159`
- `lib/screens/listing/all_listings_screen.dart:75`
- `lib/screens/listing/department_listings_screen.dart:67`
- `lib/screens/listing/pending_listings_screen.dart:123`
- `lib/screens/listing/listing_detail_screen.dart:476`
- `lib/screens/profile/edit_profile_screen.dart:49, 80`
- `lib/screens/profile/profile_screen.dart:42, 699, 1207, 1222, 1260, 1638`
- `lib/screens/profile/seller_profile_screen.dart:361`

Problem:

- `AGENTS.md` requires Firebase calls to live in services and UI to go through providers.
- `authStateProvider` calls `FirebaseAuth.instance` directly.
- `ChatDetailScreen` calls `FirebaseFirestore.instance` directly inside the widget tree.
- Many screens instantiate service classes directly instead of reading providers.

Why this matters:

- It weakens testability and makes dependency flow inconsistent.
- It spreads data-access behavior into UI code.
- It makes the project harder to reason about and easier to regress.

Needed modification:

- Move all Firebase access behind service classes.
- Expose those services only through providers.
- Refactor screens/widgets to use `ref.read(...)` / `ref.watch(...)` instead of `SomeService()`.

### 5. Medium: design-system rules are being violated widely

Files:

- `lib/data/dummy_categories.dart:4-76`
- `lib/screens/auth/welcome_screen.dart:22-27, 74, 191, 199`
- `lib/widgets/app_bottom_nav.dart:128-132, 167`
- `lib/screens/category_screen.dart:10-76`
- many other screen/widget files using inline `TextStyle(...)` and raw `Color(...)`

Problem:

- `AGENTS.md` says colors must come from `AppColors` and text styles from `AppTextStyles`.
- There are many inline `TextStyle(...)`, raw `Color(...)`, and one-off palette definitions across the app.

Why this matters:

- Visual consistency will drift over time.
- Theme changes become expensive.
- The codebase already has a standards doc, but it is not being enforced.

Needed modification:

- Consolidate repeated text styles into `AppTextStyles`.
- Map special-case colors into named constants where they are truly intentional.
- Reduce raw hex usage to the constants layer.

### 6. Medium: `Inter` is declared in theme but not configured in `pubspec.yaml`

Files:

- `lib/main.dart:49`
- `pubspec.yaml:61-97`

Problem:

- The app theme sets `fontFamily: 'Inter'`.
- `pubspec.yaml` does not declare any font assets for `Inter`.

Why this matters:

- On platforms where `Inter` is not available, Flutter will fall back silently.
- That breaks the explicit typography rule in `AGENTS.md`.

Needed modification:

- Add `Inter` properly under the `flutter.fonts` section, or use an approved existing setup if the font lives elsewhere.

### 7. Medium: route constants and screens are out of sync

Files:

- `lib/constants/app_routes.dart:18-21`
- `lib/router.dart:24-113`
- `lib/screens/category_screen.dart:1-77`

Problem:

- `AppRoutes.category` exists, and `CategoryScreen` exists, but the router never handles that route.

Why this matters:

- Dead routes/screens create confusion and hidden bugs.
- This usually signals partial implementation or abandoned navigation paths.

Needed modification:

- Either register the route properly in `AppRouter` or remove the unused route/screen after explicit approval.

### 8. Medium: several user-facing error states expose raw exception text

Files:

- `lib/screens/chat/chat_detail_screen.dart:68-72, 112-115, 170-171, 288-290`
- `lib/screens/subscription/payment_screen.dart:91-96`
- `lib/screens/profile/profile_screen.dart:1214`

Problem:

- Multiple screens show messages such as `Error: $e` or `Payment failed: $e`.
- `AGENTS.md` explicitly says not to show raw exception strings to users.

Why this matters:

- Raw exceptions are not user-friendly.
- They can leak implementation details and make support messages inconsistent.

Needed modification:

- Map failures to safe, friendly UI copy.
- Log or surface detailed errors only in developer/debug channels.

### 9. Medium: test coverage is effectively absent for critical flows

Files:

- `test/widget_test.dart:1-19`

Problem:

- The only test is a stub that pumps a basic `MaterialApp` with a `Text('UniSooq')`.
- There are no visible tests for auth, services, providers, Firestore rules, routing, or gating flows.

Why this matters:

- The riskiest parts of the app are unprotected: auth, role logic, subscription access, moderation, and chat.

Needed modification:

- Add service tests first, then provider/state tests, then targeted widget tests.
- Prioritize `AuthService`, `UserService`, `ProductService`, auth providers, and subscription/admin flows.

### 10. Low: project metadata and docs still look like a starter app

Files:

- `README.md:1-12`
- `pubspec.yaml:1-2`

Problem:

- The README is still the default Flutter starter text.
- `pubspec.yaml` still says `"A new Flutter project."`

Why this matters:

- It lowers maintainability and onboarding quality.
- The codebase is clearly beyond starter state, so the docs no longer match reality.

Needed modification:

- Replace starter metadata with real project setup, architecture notes, Firebase requirements, and run instructions.

## Recommended Modification Order

1. Lock down `firestore.rules` for `users/{uid}` immediately.
2. Remove client-side subscription activation and decide the trusted subscription flow.
3. Unify the email-domain/auth policy across docs, UI, services, and rules.
4. Refactor direct Firebase/service usage so screens read providers instead of constructing services.
5. Add high-value tests for auth, subscription, moderation, and profile permissions.
6. Clean up design-system drift, route drift, and project docs.

## Open Questions

- Is the intended email policy `@students.edu.jo`, `@asu.edu.jo`, or `@students.asu.edu.jo`?
- Is subscription supposed to be semester-based or annual? Current code/comments use both concepts.
- Should subscription activation be admin-only, payment-backed, or both?

## Overall Assessment

The project has a workable feature foundation, but it is not yet safe to treat as production-ready. The biggest blockers are security-rule overreach, client-authoritative subscription logic, and architecture drift away from the documented service/provider/UI boundaries.
