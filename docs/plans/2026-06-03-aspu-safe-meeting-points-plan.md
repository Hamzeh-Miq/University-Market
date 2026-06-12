# ASPU Safe Meeting Points Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Update campus identity text and safe meetup recommendations so they match real Applied Science Private University locations.

**Architecture:** Existing layered UniSooq architecture with Riverpod

**Dependencies:** None

---

### Task 1: Update Safety Guide Meeting Zones

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/about/campus_safety_guide_screen.dart`

**Implementation:**
- Replace generic or placeholder meetup points with Applied Science Private University locations supported by official campus references.
- Prefer visible, staffed, high-traffic places such as the main library, book shop/cafeteria corridor, mosque area, and parking-facing pickup points.

**Verification:**
- `flutter analyze lib/screens/about/campus_safety_guide_screen.dart`

### Task 2: Correct University Identity Copy

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/about/about_us_screen.dart`

**Implementation:**
- Replace remaining `University of Jordan` references with `Applied Science Private University`.
- Update location copy to refer to the university’s Amman campus on Al Arab Street.

**Verification:**
- `flutter analyze lib/screens/about/about_us_screen.dart`

### Task 3: Final Verification

**Layer:** Verification

**Files:**
- Modify as needed from previous tasks

**Implementation:**
- Format touched files if needed.
- Run targeted Flutter analysis for the updated about and safety-guide screens.

**Verification:**
- `dart format lib/screens/about/about_us_screen.dart lib/screens/about/campus_safety_guide_screen.dart`
- `flutter analyze lib/screens/about/about_us_screen.dart lib/screens/about/campus_safety_guide_screen.dart`
