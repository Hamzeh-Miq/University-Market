# Premium UI Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Rework UniSooq's visual design layer into a premium Material 3 campus marketplace experience while preserving the existing layered architecture.

**Architecture:** Existing layered Flutter architecture with Riverpod providers, services, models, screens, widgets, and constants.

**Dependencies:** No new packages in the initial implementation. A third-party animated nav package such as `google_nav_bar` requires explicit user approval before adding.

---

## Batch 1: Design Foundation And Marketplace Cards

### Task 1: Expand Design Tokens

**Layer:** Presentation

**Files:**
- Modify: `lib/constants/app_colors.dart`
- Modify: `lib/constants/app_text_styles.dart`

**Implementation:**
- Add auth gradient colors, internal canvas colors, premium accent blue, crimson favourite accent, glass border/fill, and neutral chip colors.
- Add centralized gradients, shadow colors, and radius constants.
- Add compact marketplace typography for section titles, card titles, metadata, prices, chips, and auth text.

**Verification:**
```bash
dart format lib/constants/app_colors.dart lib/constants/app_text_styles.dart
flutter analyze
```

### Task 2: Add Shared Premium UI Primitives

**Layer:** Presentation

**Files:**
- Modify: `lib/widgets/common_widgets.dart`

**Implementation:**
- Add `GradientActionButton`, `PremiumIconButton`, `PremiumSearchField`, `PremiumSectionHeader`, `PremiumEmptyState`, and `CategoryBadge`.
- Keep widgets Firebase-free and Riverpod-free.
- Use AppColors/AppTextStyles only.

**Verification:**
```bash
dart format lib/widgets/common_widgets.dart
flutter analyze
```

### Task 3: Upgrade Product Card

**Layer:** Presentation

**Files:**
- Modify: `lib/widgets/product_card.dart`

**Implementation:**
- Convert product cards to square image marketplace cards with `AspectRatio`.
- Overlay heart icon on top-right.
- Add title, location row, and highlighted JD price.
- Guard text overflow with maxLines, ellipsis, fixed image ratio, and predictable padding.

**Verification:**
```bash
dart format lib/widgets/product_card.dart
flutter analyze
```

### Task 4: First-Pass Home Dashboard Redesign

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

**Implementation:**
- Build bright app canvas with UniSooq header, saved/chat icon buttons, rounded search field, circular category badges, urgent deals carousel, new-listings banner, and trending product grid.
- Use existing providers and routes; do not add new routes.
- Keep empty/loading/error states user-friendly.

**Verification:**
```bash
dart format lib/screens/home/home_screen.dart
flutter analyze
flutter test
flutter build apk --debug
```

---

## Batch 2: Auth Layer Redesign

### Task 5: Glassmorphic Auth Background

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/auth/welcome_screen.dart`
- Modify: `lib/screens/auth/login_screen.dart`

**Implementation:**
- Add deep-blue gradient auth background.
- Add low-opacity academic icon silhouettes using Flutter `Icon` widgets.
- Wrap login/register forms in blurred glass panels using `BackdropFilter`.
- Apply focused input glow, prefix icons, password visibility suffix, and gradient primary actions.

**Verification:**
```bash
dart format lib/screens/auth/welcome_screen.dart lib/screens/auth/login_screen.dart
flutter analyze
flutter test
```

---

## Batch 3: Listings And Upload Flow

### Task 6: Listing Grids And Filters

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/listing/all_listings_screen.dart`
- Modify: `lib/screens/listing/department_listings_screen.dart`
- Modify: `lib/screens/listing/favourite_listings_screen.dart`

**Implementation:**
- Replace wide cards with reusable two-column marketplace grids.
- Replace custom category rows with Material 3 `ChoiceChip` filter rows.
- Upgrade favourites empty state and saved-count subheader.

### Task 7: Add/Edit Listing Form Styling

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/listing/add_listing_screen.dart`
- Modify: `lib/screens/listing/edit_listing_screen.dart`

**Implementation:**
- Add horizontal multi-photo tray with dashed add-photo box and removable thumbnails.
- Replace stock category dropdown with custom bottom sheet.
- Apply rounded off-white input fields and focus glow styling.

---

## Batch 4: Profile, Admin, About, And Chat

### Task 8: About Screen

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/about/about_us_screen.dart`

**Implementation:**
- Add SliverAppBar, roadmap timeline, BI stats module, and tappable support rows.

### Task 9: Profile/Admin Split

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/screens/profile/edit_profile_screen.dart`

**Implementation:**
- Add `SegmentedButton` or `TabBar` split for profile/admin.
- Style profile counters, personal information, my listings, moderation cards, empty states, and lookup panel.

### Task 10: Messages And Chat

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/chat/chat_list_screen.dart`
- Modify: `lib/screens/chat/chat_detail_screen.dart`

**Implementation:**
- Add premium inbox rows, sticky listing context header, asymmetric message bubbles, date chips, and rounded input action deck.

---

## Batch 5: Navigation And Verification

### Task 11: Custom Bottom Navigation

**Layer:** Presentation

**Files:**
- Modify: `lib/widgets/app_bottom_nav.dart`

**Implementation:**
- Build a custom animated pill navigation bar using Flutter widgets only.
- Keep the center create-listing action visually dominant without adding a package.

### Task 12: Full Verification

**Layer:** Test

**Files:**
- Existing test suite

**Verification:**
```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```
