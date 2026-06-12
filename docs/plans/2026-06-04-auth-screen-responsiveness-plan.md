# Auth Screen Responsiveness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Make the email verification and 2FA screen adapt safely to narrow and short phones without overflow.

**Architecture:** Existing layered UniSooq architecture with Riverpod

**Dependencies:** None

---

### Task 1: Make Layout Spacing Responsive

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/auth/email_verification_screen.dart`

**Implementation:**
- Add responsive spacing, radius, and card padding using `MediaQuery`/`LayoutBuilder`.
- Reduce header/card vertical footprint on compact devices.
- Respect keyboard insets so the form stays scrollable when the keyboard is open.

**Verification:**
- `flutter analyze lib/screens/auth/email_verification_screen.dart`

### Task 2: Harden Text And Actions Against Overflow

**Layer:** Presentation

**Files:**
- Modify: `lib/screens/auth/email_verification_screen.dart`

**Implementation:**
- Ensure long status messages and action labels can wrap safely.
- Keep buttons and info pills readable on narrow widths.
- Preserve existing auth flow and messaging.

**Verification:**
- `flutter analyze lib/screens/auth/email_verification_screen.dart`

### Task 3: Final Verification

**Layer:** Verification

**Files:**
- Modify as needed from previous tasks

**Implementation:**
- Format the screen file.
- Run targeted Flutter analysis.

**Verification:**
- `dart format lib/screens/auth/email_verification_screen.dart`
- `flutter analyze lib/screens/auth/email_verification_screen.dart`
