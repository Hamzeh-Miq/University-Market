# Product Status Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Finish product post statuses so listings move through pending, published, sold, and deleted with owner/admin controls and sold rankings on About.

**Architecture:** Layered Flutter architecture with Riverpod

**Dependencies:** No new packages

---

### Task 1: Product Status Constants

**Layer:** Data

**Files:**
- Create: `lib/constants/product_status.dart`
- Modify: `lib/models/product_model.dart`

**Implementation:**
- Add canonical status values: `pending`, `published`, `sold`.
- Add legacy aliases for existing `Pending`, `Available`, `Sold` data.
- Normalize status reads so old Firestore documents still work.
- Expose display labels and color/status helpers.

**Verification:**
```bash
flutter analyze lib/constants/product_status.dart lib/models/product_model.dart
```

### Task 2: Product Service Status Queries and Actions

**Layer:** Data

**Files:**
- Modify: `lib/services/product_service.dart`

**Implementation:**
- Query public listings with published plus legacy available.
- Query pending and sold listings with canonical plus legacy values.
- Approve products by setting status to published.
- Mark products sold by setting status to sold and `soldAt`.
- Keep deleted as hard delete through existing `deleteProduct`.

**Verification:**
```bash
flutter analyze lib/services/product_service.dart
```

### Task 3: Providers and UI Wiring

**Layer:** Presentation

**Files:**
- Modify: `lib/providers/product_provider.dart`
- Modify: `lib/screens/listing/add_listing_screen.dart`
- Modify: `lib/screens/listing/edit_listing_screen.dart`
- Modify: `lib/screens/listing/listing_detail_screen.dart`
- Modify: `lib/screens/listing/pending_listings_screen.dart`
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/screens/profile/seller_profile_screen.dart`
- Modify: `lib/screens/about/about_us_screen.dart`

**Implementation:**
- Use status constants in providers and screens.
- Show sold/delete actions only for admin or owner.
- Confirm sold and delete actions with dialogs.
- Refresh product/detail/listing providers after status changes.
- Render sold ranking paragraph/cards at the bottom of About.

**Verification:**
```bash
flutter analyze
flutter test
```
