import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Service to handle media uploads to Firebase Storage.
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads raw bytes to Firebase Storage and returns the public download URL.
  static Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Firebase Storage upload failed: $e');
    }
  }
}
