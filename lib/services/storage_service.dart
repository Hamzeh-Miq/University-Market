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
