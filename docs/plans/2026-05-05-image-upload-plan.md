# Image Upload Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Allow users to pick up to 5 images, compress them locally, and upload them to Firebase Storage when creating a listing.

**Architecture:** Clean Architecture with Riverpod

**Dependencies:**
```bash
flutter pub add image_picker firebase_storage uuid
```

---

## Data Layer

### Task 1: StorageService
**Layer:** Data
**Files:**
- Create: `lib/services/storage_service.dart`

**Implementation:**
```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Compresses and uploads an image to Firebase Storage, returning the download URL.
  Future<String> compressAndUploadImage(File imageFile) async {
    try {
      // 1. Compress image to Uint8List
      final Uint8List? compressedData = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 75,
      );

      if (compressedData == null) {
        throw Exception('Failed to compress image.');
      }

      // 2. Generate unique file name
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('products').child(fileName);

      // 3. Upload data
      final UploadTask uploadTask = ref.putData(
        compressedData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;

      // 4. Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
```

**Verification:**
```bash
flutter analyze lib/services/storage_service.dart
```

---

## Presentation Layer

### Task 2: AddListingScreen Image Picker
**Layer:** Presentation
**Files:**
- Modify: `lib/screens/listing/add_listing_screen.dart`

**Implementation:**
*(Will be executed using `multi_replace_file_content` to add state `List<File> _selectedImages`, an image picker function, horizontal list view for thumbnails, and updating `_submit` to loop through `_selectedImages` uploading via `StorageService` before creating the product.)*

**Verification:**
```bash
flutter analyze lib/screens/listing/add_listing_screen.dart
```

### Task 3: ListingDetailScreen Carousel
**Layer:** Presentation
**Files:**
- Modify: `lib/screens/listing/listing_detail_screen.dart`

**Implementation:**
*(Will replace `Icon(Icons.image_outlined)` in `SliverAppBar` with a `PageView.builder` to display `product.images` using `Image.network`.)*

**Verification:**
```bash
flutter analyze lib/screens/listing/listing_detail_screen.dart
```

### Task 4: ProductListings Thumbnail
**Layer:** Presentation
**Files:**
- Modify: `lib/screens/listing/department_listings_screen.dart`

**Implementation:**
*(Will modify `_ProductListTile` to use `Image.network(product.images.first)` instead of the placeholder `Icon` if `product.images.isNotEmpty`.)*

**Verification:**
```bash
flutter analyze lib/screens/listing/department_listings_screen.dart
```

---

## Testing

### Task 5: Verify Build
**Layer:** Test
**Files:** N/A

**Verification:**
```bash
flutter analyze
flutter test
```
