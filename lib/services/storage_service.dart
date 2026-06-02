import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Compresses and uploads an image to Firebase Storage, returning the download URL.
  Future<String> compressAndUploadImage(XFile imageFile) async {
    try {
      Uint8List data;

      if (kIsWeb) {
        data = await imageFile.readAsBytes();
      } else {
        // 1. Compress image to Uint8List on mobile
        final Uint8List? compressedData =
            await FlutterImageCompress.compressWithFile(
              imageFile.path,
              minWidth: 800,
              minHeight: 800,
              quality: 75,
            );

        if (compressedData == null) {
          throw Exception('Failed to compress image.');
        }
        data = compressedData;
      }

      // 2. Generate unique file name
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('products').child(fileName);

      // 3. Upload data
      final UploadTask uploadTask = ref.putData(
        data,
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
