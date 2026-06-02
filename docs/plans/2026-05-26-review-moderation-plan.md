# Review Moderation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Allow reviewers to edit or delete their reviews, allow profile owners to report reviews for admin review, require review text, let admins delete reviews, and keep user rating aggregates correct after every review mutation.

**Architecture:** Existing layered architecture with Riverpod providers and Firebase services

**Dependencies:** None

---

### Task 1: Extend Review And Report Models

**Layer:** Data

**Files:**
- Modify: `lib/models/review_model.dart`
- Modify: `lib/models/report_model.dart`

**Implementation:**
- Add fields needed to display reviewer identity and track edits on reviews.
- Add review-report reason choices and allow `ReportModel.targetType` to represent review reports.

**Verification:**
- `flutter analyze lib/models/review_model.dart lib/models/report_model.dart`

### Task 2: Add Review Mutation And Aggregate Logic

**Layer:** Data

**Files:**
- Modify: `lib/services/review_service.dart`

**Implementation:**
- Keep review create/edit/delete operations in transactions.
- Recompute the reviewee’s `rating` and `reviewCount` inside the same transaction whenever a review changes.
- Add helper methods to fetch the current user’s review for a given profile and to delete a review by id.

**Verification:**
- `flutter analyze lib/services/review_service.dart`

### Task 3: Expose Review State Through Providers

**Layer:** Presentation

**Files:**
- Modify: `lib/providers/review_provider.dart`

**Implementation:**
- Replace the boolean “has reviewed” flow with provider access to the current reviewer’s existing review.
- Keep the reviews list stream intact for the profile page.

**Verification:**
- `flutter analyze lib/providers/review_provider.dart`

### Task 4: Update Profile Review UX

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/profile/seller_profile_screen.dart`

**Implementation:**
- Make review text mandatory on create and edit.
- Show existing review data in the form so the reviewer can update or delete it.
- Let the profile owner report individual reviews.
- Surface reviewer names and edited state in the review list.

**Verification:**
- `flutter analyze lib/screens/profile/seller_profile_screen.dart`

### Task 5: Extend Admin Report Handling

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Reuse: `lib/services/report_service.dart`

**Implementation:**
- Make review reports visible in the existing admin reports panel.
- Add an admin action that deletes the reported review and marks the report reviewed.

**Verification:**
- `flutter analyze lib/screens/profile/profile_screen.dart`

### Task 6: Format And Verify

**Layer:** Test / Integration

**Files:**
- Modify: any touched files above

**Implementation:**
- Run formatter and project verification commands required by the repo.

**Verification:**
- `dart format lib/`
- `flutter analyze`
- `flutter test`
