# Admin Approval & Contextual Controls Design

## Overview
Introduce a role-based system to UniTrade where specific accounts (Admins) can review, approve, and manage marketplace listings and user accounts contextually without a separate dashboard.

## User Stories
- As an Admin, I want to see a queue of pending listings so I can approve them for the marketplace.
- As an Admin, I want to be able to delete or edit any post to maintain quality.
- As an Admin, I want to manage user accounts directly from their profile pages.
- As a Seller, I want to see my pending items so I know they are awaiting approval.
- As a Buyer, I should only see available, approved items.

## Clean Architecture

### Domain Layer
- Entities: User (add role), Product (add pending status).

### Data Layer
- Models: `UserModel` (add `String role`), `ProductModel` (ensure `status` supports 'pending').
- DataSources: Firestore collections (`users`, `products`).
- Repository implementations: `UserService`, `ProductService`, `AuthService`.

### Presentation Layer
- State Management: Riverpod (`authProvider`, `productListProvider`).
- Screens: `HomeScreen` (add pending toggle for admins), `ListingDetailScreen` (contextual buttons), `ProfileScreen` (contextual buttons).

## Data Flow
1. User registration/login -> `AuthService` checks for `202120554@students.asu.edu.jo`. If matched, `role` is set to `admin`.
2. Seller creates product -> `ProductService` sets status to `pending`.
3. Admin views `HomeScreen` -> Toggles to "Pending Approvals".
4. Admin views `ListingDetailScreen` -> Toggles status to `Available` via "Approve" button.
5. Stream updates UI for all users.

## Testing Plan
- Unit tests: `AuthService` (admin assignment), `ProductService` (fetch logic).

## Dependencies
None.
