import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/mock/mock_catalog.dart';
import '../../data/search/search_synonyms.dart';
import '../../firebase_options.dart';
import '../constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class MazonnFirebase {
  static const storageBucket = 'mazonn-ecommerce-and-pos.firebasestorage.app';

  static bool get isReady => Firebase.apps.isNotEmpty;

  /// Android's Storage SDK 404s on the newer `.firebasestorage.app` bucket name.
  static FirebaseStorage get storage =>
      FirebaseStorage.instanceFor(bucket: 'gs://$storageBucket');

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
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleWebClientId,
      );
    } catch (_) {}
    await seedCatalogIfNeeded();
    return true;
  }

  static Future<void> seedCatalogIfNeeded() async {
    if (!isReady) return;
    try {
      final products = FirebaseFirestore.instance.collection('products');
      final meta = FirebaseFirestore.instance.collection('meta').doc('catalog');
      final existing = await products.limit(1).get();
      if (existing.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final product in MockCatalog.products) {
          batch.set(products.doc(product.id), product.toJson());
        }
        batch.set(FirebaseFirestore.instance.collection('searchConfig').doc('default'), SearchSynonymTable.defaults().toJson());
        batch.set(meta, {'version': 5, 'seed': true});
        await batch.commit();
        return;
      }
      final version = (await meta.get()).data()?['version'] as int? ?? 0;
      if (version >= 5) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final product in MockCatalog.products) {
        batch.set(products.doc(product.id), product.toJson(), SetOptions(merge: true));
      }
      batch.set(
        FirebaseFirestore.instance.collection('searchConfig').doc('default'),
        SearchSynonymTable.defaults().toJson(),
        SetOptions(merge: true),
      );
      batch.set(meta, {'version': 5, 'seed': true}, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {
      // Seeding is best-effort; the bundled catalog is used until Firestore is writable.
    }
  }
}
