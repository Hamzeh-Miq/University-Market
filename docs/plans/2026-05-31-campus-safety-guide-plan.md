# Campus Safety Guide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Add a polished informational trust screen with safe campus exchange zones and transaction safety tips.

**Architecture:** Existing layered Flutter architecture with static presentation-only widgets.

**Dependencies:** None.

---

## Presentation Layer

### Task 1: Campus Safety Guide Screen

**Layer:** Presentation

**Files:**
- Create: `lib/screens/about/campus_safety_guide_screen.dart`

**Implementation:**
- Build a `StatelessWidget` informational screen.
- Use `CustomScrollView`, a polished header, safe exchange zone cards, guideline cards, and safety checklist rows.
- Use existing `AppColors`, `AppTextStyles`, and `AppBottomNav`.
- Keep the content static and dependency-free.

**Verification:**
```bash
dart format lib/screens/about/campus_safety_guide_screen.dart
flutter analyze
```

### Task 2: Named Route Wiring

**Layer:** Presentation

**Files:**
- Modify: `lib/constants/app_routes.dart`
- Modify: `lib/router.dart`

**Implementation:**
- Add `AppRoutes.campusSafetyGuide`.
- Register the route in `AppRouter.generateRoute`.
- Keep the About tab highlighted in the bottom nav by passing `AppRoutes.aboutUs` to `AppBottomNav`.

**Verification:**
```bash
flutter analyze
flutter test
flutter build apk --debug
```
