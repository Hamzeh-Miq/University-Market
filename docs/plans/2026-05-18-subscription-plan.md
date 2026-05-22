# Semester Subscription Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Add a freemium semester subscription model — non-subscribers see 6 preview listings with no filters/messaging/posting; admin manually activates subscriptions lasting 4 months (120 days).

**Architecture:** Layered architecture with Riverpod v2 (matches existing project)

**Dependencies:** None — no new packages required.

**Subscription Constant:** `kSubscriptionDays = 120` (4 months)
**Preview limit:** `kFreePreviewLimit = 6` listings

---

## Layer 1 — Model

### Task 1: Update UserModel
**Files:** Modify `lib/models/user_model.dart`

Add fields:
- `bool isSubscribed` (default `false`)
- `DateTime? subscriptionExpiresAt`
- `DateTime? subscriptionActivatedAt`

Update `fromJson` and `toJson`.

---

## Layer 2 — Service

### Task 2: Update UserService
**Files:** Modify `lib/services/user_service.dart`

Add two methods:
- `activateSubscription(String uid)` — sets `isSubscribed: true`, `subscriptionActivatedAt: now`, `subscriptionExpiresAt: now + 120 days`
- `revokeSubscription(String uid)` — sets `isSubscribed: false`

Also add:
- `searchUserByEmail(String email)` — queries `users` collection where `email == email`, returns first match `UserModel?`

---

## Layer 3 — Providers

### Task 3: Add subscription providers
**Files:** Modify `lib/providers/auth_provider.dart`

Add:
- `hasActiveSubscriptionProvider` — `Provider<bool>` that checks `currentUserModelProvider.value?.isSubscribed == true && subscriptionExpiresAt?.isAfter(DateTime.now()) == true`

---

## Layer 4 — Constants

### Task 4: Add subscription constants
**Files:** Modify `lib/constants/app_routes.dart`

Add route: `static const String subscriptionManagement = '/admin/subscriptions';`

Create `lib/constants/subscription_constants.dart`:
- `kSubscriptionDays = 120`
- `kFreePreviewLimit = 6`
- `kSubscriptionPriceDisplay = 'Contact admin for pricing'`

---

## Layer 5 — Widget

### Task 5: Create SubscriptionGateWidget
**Files:** Create `lib/widgets/subscription_gate.dart`

A reusable widget that:
- Takes a `child` widget and a `featureLabel` string
- If `hasActiveSubscriptionProvider` is true → shows `child`
- If false → shows a locked placeholder card with a "Subscribe to unlock [featureLabel]" button that opens `_showSubscriptionBottomSheet(context)`
- Bottom sheet: premium design showing what subscribers get, semester price, "Contact admin to subscribe" CTA

---

## Layer 6 — Screens (Presentation)

### Task 6: Update AllListingsScreen — gate filters
**Files:** Modify `lib/screens/listing/all_listings_screen.dart`

- Wrap filter bar in `SubscriptionGate(featureLabel: 'filters')`
- If non-subscriber, hide filter widgets and show lock banner

### Task 7: Update HomeScreen — limit preview listings  
**Files:** Modify `lib/screens/home/home_screen.dart`

- Lock "Sell Now" / "Post Your Ad" button for non-subscribers (show gate)
- Add a preview banner strip at bottom: "You're viewing 6 of X listings. Subscribe for full access."

### Task 8: Update AddListingScreen — gate posting
**Files:** Modify `lib/screens/listing/add_listing_screen.dart`

- At top of `build`, check `hasActiveSubscriptionProvider`; if false, return `SubscriptionGate` full-page prompt instead of the form

### Task 9: Update ListingDetailScreen / ChatList — gate messaging
**Files:** Modify `lib/screens/listing/listing_detail_screen.dart`

- "Message Seller" button: check subscription; if false show `SubscriptionGate` inline

### Task 10: Add SubscriptionStatusCard to ProfileScreen
**Files:** Modify `lib/screens/profile/profile_screen.dart`

Add a card below the stats row:
- Subscribed: green badge "✅ Active — expires [date]"
- Not subscribed: amber banner "🔒 Free Preview — Subscribe to unlock everything"

### Task 11: Add Admin Subscription Management section to ProfileScreen
**Files:** Modify `lib/screens/profile/profile_screen.dart`

New `_AdminSubscriptionSection` widget (shown only to admins, below existing `_AdminApprovalsSection`):
- Email search text field
- "Find User" button → calls `UserService().searchUserByEmail()`
- Shows found user name + current subscription status
- "Activate Subscription (120 days)" button → calls `UserService().activateSubscription(uid)`
- "Revoke" button → calls `UserService().revokeSubscription(uid)`

---

## Layer 7 — Firestore Rules

### Task 12: Update firestore.rules
**Files:** Modify `firestore.rules`

Ensure `isSubscribed`, `subscriptionExpiresAt`, `subscriptionActivatedAt` fields on `users/{uid}` can only be written by admin (role == 'admin') or by a Cloud Function — not by the user themselves.

---

## Layer 8 — Product Provider (preview limit)

### Task 13: Update productListProvider to enforce preview limit
**Files:** Modify `lib/providers/product_provider.dart`

The provider family should accept an optional `isSubscribed` parameter; when false, call `.take(kFreePreviewLimit)` on the results.

**OR** (simpler): Apply the limit in the UI layer — the home/all-listings screens read `hasActiveSubscriptionProvider` and call `.take(6)` on the list before rendering.

Use the UI-layer approach to avoid changing the service signature.

---

## Verification

```bash
flutter analyze
flutter pub get
flutter build apk --debug
```

No new packages added — no `flutter pub add` needed.
