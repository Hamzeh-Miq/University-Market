# UniSooq

UniSooq is a Flutter marketplace app for Applied Science Private University students. It supports student-only authentication, moderated listings, peer messaging, profiles, reviews, and admin-managed subscriptions.

## Stack

- Flutter 3 / Dart 3
- Riverpod v2
- Firebase Auth
- Cloud Firestore
- Firebase Storage

## Project Structure

The app follows the layered structure documented in `AGENTS.md`:

- `lib/models/` data models only
- `lib/services/` Firebase access only
- `lib/providers/` Riverpod dependency and state wiring
- `lib/screens/` feature UI
- `lib/widgets/` reusable UI pieces
- `lib/constants/` design system and routes

## Student Access Policy

- Registration is restricted to `@students.asu.edu.jo`
- Email verification is required before marketplace access
- Admin account checks target `202120554@students.asu.edu.jo`

## Setup

1. Install Flutter and Firebase CLI.
2. Run `flutter pub get`.
3. Ensure Firebase configuration files are present.
4. Start the app with `flutter run`.

## Verification

Run these before shipping changes:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Firebase Notes

- Do not edit `lib/firebase_options.dart` manually.
- Keep Firestore access behind services and providers.
- Test security rule changes with the Firebase emulator before deployment.
