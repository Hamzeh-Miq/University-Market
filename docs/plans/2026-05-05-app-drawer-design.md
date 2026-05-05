# App Drawer Navigation Design

## Overview
Implement a side navigation drawer (`AppDrawer`) on the `HomeScreen` to consolidate navigation links, provide an expandable list of departments, and clean up the top AppBar.

## Clean Architecture

### Presentation Layer
- **`lib/widgets/app_drawer.dart` (New)**: A standalone `ConsumerWidget` that returns a `Drawer`.
  - Reads `currentUserModelProvider` to determine if the "Pending Approvals" button should be shown.
  - Utilizes `dummyCategories` to build an `ExpansionTile` containing `ListTile`s for each department.
- **`lib/screens/home/home_screen.dart`**:
  - Add `drawer: const AppDrawer()` to the `Scaffold`.
  - Remove "About Us", "Profile", and "Admin" IconButtons from the `AppBar` `actions` array to reduce clutter.

## Data Flow & Navigation
- No changes to Data/Domain layers.
- All drawer links navigate using existing `AppRoutes` via `Navigator.pushNamed`.
- Selecting a department passes the `category.name` argument to `AppRoutes.departmentListings`.
