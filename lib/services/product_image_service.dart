import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/firebase/mazonn_firebase.dart';

class ProductImageService {
  static const allowedTypes = {'image/jpeg', 'image/jpg', 'image/png', 'image/webp'};
  static const maxBytes = 8 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pick({bool camera = false}) async {
    if (camera) {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 88, maxWidth: 2000);
      return file == null ? [] : [file];
    }
    return _picker.pickMultiImage(imageQuality: 88, maxWidth: 2000);
  }

  Future<String> upload({
    required String productId,
    required XFile file,
    required int index,
    void Function(double progress)? onProgress,
  }) async {
    if (!MazonnFirebase.isReady) {
      throw StateError('Image storage is unavailable. Connect Firebase Storage and try again.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw StateError('Each image must be under 8 MB.');
    }
    final mime = file.mimeType ?? _guessMime(file.name);
    if (!allowedTypes.contains(mime)) {
      throw StateError('Use JPEG, PNG, or WebP images.');
    }
    final path = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    final ref = MazonnFirebase.storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: mime));
    task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total > 0) onProgress?.call(snap.bytesTransferred / total);
    });
    await task;
    return ref.getDownloadURL();
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
