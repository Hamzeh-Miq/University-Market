# Favourite Listings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Add a favourites page where students can view saved posts, remove posts from favourites, open item details, and contact sellers.

**Architecture:** Layered Flutter architecture with Riverpod providers.

**Dependencies:** None.

---

## Design

The feature uses the existing `watchlistProvider` as the source of favourite product IDs. Product data is loaded through `ProductService`, exposed through `product_provider.dart`, and rendered by a new screen in `lib/screens/listing/`. The home AppBar gets a favourite icon next to the chat icon. Listing rows and listing details expose bookmark controls so users can add and remove posts.

## Tasks

### Task 1: Favourite Products Query

**Layer:** Services / Providers

**Files:**
- Modify: `lib/services/product_service.dart`
- Modify: `lib/providers/product_provider.dart`

**Implementation:** Add a batched Firestore lookup for selected product IDs and a `favoriteProductsProvider` that watches the existing `watchlistProvider`.

### Task 2: Favourite Listings Screen

**Layer:** Presentation

**Files:**
- Create: `lib/screens/listing/favourite_listings_screen.dart`

**Implementation:** Show loading, error, empty, and data states. Each favourite item can be tapped for details, removed from favourites, or used to open a seller chat.

### Task 3: Navigation And Entry Points

**Layer:** Presentation / Routing

**Files:**
- Modify: `lib/constants/app_routes.dart`
- Modify: `lib/router.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/listing/all_listings_screen.dart`
- Modify: `lib/screens/listing/listing_detail_screen.dart`

**Implementation:** Register the named route, add the AppBar icon near chat, and add favourite toggle controls in listing browsing and detail views.

## Verification

Run:

```bash
dart format lib/ docs/plans/2026-05-30-favourite-listings-plan.md
flutter analyze
flutter test
flutter build apk --debug
```
