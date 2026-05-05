# Image Upload Design

## Overview
Allow users to attach up to 5 images to their marketplace listings. Images will be picked from the device camera or gallery, compressed locally, and uploaded to Firebase Storage.

## User Stories
- As a Seller, I want to upload photos of my item so buyers can see its condition.
- As a Seller, I want to take a new photo or select existing ones from my gallery.
- As a Seller, I want to remove an image if I selected the wrong one.
- As a Buyer, I want to swipe through multiple images on the listing details screen.

## Clean Architecture

### Domain Layer
- Entities: Product (already has `List<String> images`).

### Data Layer
- Models: No changes needed to `ProductModel` (already supports `images`).
- DataSources: Firebase Storage for images.
- Repository implementations: `StorageService` (new) to handle compression and upload.

### Presentation Layer
- Screens: 
  - `AddListingScreen`: Horizontal list of selected images, "Add Image" bottom sheet, loading state during upload.
  - `ListingDetailScreen`: `PageView` image carousel.
  - `HomeScreen` / `DepartmentListingsScreen`: Update product cards to show thumbnail.

## Data Flow
1. User selects images using `ImagePicker`.
2. Selected `XFile`s are kept in the state of `AddListingScreen`.
3. On form submit, loop through `XFile`s.
4. `StorageService.compressAndUploadImage()` is called for each file.
5. `flutter_image_compress` compresses the image to `Uint8List`.
6. Upload to Firebase Storage `products/<uuid>.jpg`.
7. Get download URLs and set to `ProductModel.images`.
8. Call `ProductService.addProduct()`.

## Dependencies
- `image_picker`
- `firebase_storage`
- `uuid`
- `flutter_image_compress` (already installed)

## Testing Plan
- Unit tests: `StorageService` mock compression/upload handling.
