import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/mock/mock_catalog.dart';
import '../../firebase_options.dart';
import '../constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class MazonnFirebase {
  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<bool> ensureInitialized() async {
    if (!DefaultFirebaseOptions.isConfigured) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (_) {
      return false;
    }
    try {
      final webClientId = AppConstants.googleWebClientId;
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
    } catch (_) {}
    await seedCatalogIfNeeded();
    return true;
  }

  static Future<void> seedCatalogIfNeeded() async {
    if (!isReady) return;
    try {
      final products = FirebaseFirestore.instance.collection('products');
      final existing = await products.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final product in MockCatalog.products) {
        batch.set(products.doc(product.id), product.toJson());
      }
      await batch.commit();
    } catch (_) {
      // Seeding is best-effort; the bundled catalog is used until Firestore is writable.
    }
  }
}
