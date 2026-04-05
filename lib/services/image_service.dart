// lib/services/image_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 200,      // Small size for base64
        maxHeight: 200,
        imageQuality: 50,   // Compress
      );
      return image;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Upload as base64 to Firestore (NO STORAGE NEEDED!)
  Future<String?> uploadProfilePhoto({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      debugPrint('📤 Processing image...');

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Create data URL
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      debugPrint('📦 Image size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set({
        'photoBase64': dataUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Photo saved to Firestore!');
      return dataUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoBase64': FieldValue.delete(),
        'photoUpdatedAt': FieldValue.delete(),
      });
      debugPrint('✅ Photo deleted!');
      return true;
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      return false;
    }
  }
}