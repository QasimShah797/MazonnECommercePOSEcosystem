import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/firebase/mazonn_firebase.dart';

class VendorDocumentService {
  static const maxBytes = 8 * 1024 * 1024;
  static const maxFirestoreBytes = 700 * 1024;
  static const allowedTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  };

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) =>
      _picker.pickImage(source: source, imageQuality: 62, maxWidth: 1280);

  Future<String> upload({
    required String vendorId,
    required XFile file,
    required String kind,
  }) async {
    if (!MazonnFirebase.isReady) {
      throw StateError('Document storage is unavailable. Connect Firebase and try again.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw StateError('Each file must be under 8 MB.');
    }
    var mime = file.mimeType ?? _guessMime(file.name);
    if (mime == 'image/jpg') mime = 'image/jpeg';
    if (!allowedTypes.contains(mime)) {
      throw StateError('Use JPEG, PNG, WebP, or PDF files.');
    }
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'vendors/$vendorId/documents/${DateTime.now().millisecondsSinceEpoch}_${kind}_$safeName';
    try {
      final ref = MazonnFirebase.storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (!_isMissingStorage(e)) {
        throw StateError(_storageMessage(e));
      }
      try {
        return await _storeInFirestore(vendorId: vendorId, kind: kind, bytes: bytes, mime: mime);
      } catch (_) {
        if (bytes.length > maxFirestoreBytes) {
          throw StateError('Choose a clearer, smaller photo (under 700 KB) and try again.');
        }
        return 'data:$mime;base64,${base64Encode(bytes)}';
      }
    }
  }

  bool _isMissingStorage(FirebaseException e) {
    final message = (e.message ?? '').toLowerCase();
    return e.code == 'object-not-found' ||
        e.code == 'bucket-not-found' ||
        e.code == 'retry-limit-exceeded' ||
        e.code == 'canceled' ||
        e.code == 'unknown' ||
        message.contains('not found') ||
        message.contains('404');
  }

  Future<String> _storeInFirestore({
    required String vendorId,
    required String kind,
    required List<int> bytes,
    required String mime,
  }) async {
    if (bytes.length > maxFirestoreBytes) {
      throw StateError('Choose a clearer, smaller photo (under 700 KB) and try again.');
    }
    final id = '${vendorId}_$kind';
    await FirebaseFirestore.instance.collection('vendorKyc').doc(id).set({
      'vendorId': vendorId,
      'type': kind,
      'mime': mime,
      'base64': base64Encode(bytes),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return 'kyc:$id';
  }

  String _storageMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return 'You must be signed in as this vendor to upload documents.';
      case 'object-not-found':
      case 'bucket-not-found':
        return 'Document storage is not available. Enable Firebase Storage for this project.';
      case 'canceled':
        return 'Upload was cancelled.';
      default:
        return e.message?.isNotEmpty == true ? e.message! : 'Upload failed.';
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }
}
