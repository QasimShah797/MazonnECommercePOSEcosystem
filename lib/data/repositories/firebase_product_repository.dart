import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firebase/mazonn_firebase.dart';
import '../../models/catalog_extras.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../catalog_query.dart';
import '../mock/mock_catalog.dart';
import 'mock_product_repository.dart';
import 'product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  final MockProductRepository _fallback = MockProductRepository();

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  Future<List<Product>> _marketplace() async {
    if (!MazonnFirebase.isReady) return _fallback.fetchProducts();
    await MazonnFirebase.seedCatalogIfNeeded();
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _products
            .where('moderation', isEqualTo: 'approved')
            .where('vendorApprovalStatus', isEqualTo: 'approved')
            .get();
      } catch (_) {
        snapshot = await _products.where('moderation', isEqualTo: 'approved').get();
      }
      if (snapshot.docs.isEmpty) {
        return (await _fallback.fetchProducts()).where((p) => p.isMarketplaceVisible).toList();
      }
      final remote = snapshot.docs
          .map((doc) => _hydrateSeed(Product.fromJson(doc.data())))
          .where((p) => p.isMarketplaceVisible)
          .toList();
      final ids = {for (final p in remote) p.id};
      final extras = MockCatalog.products.where((p) => p.isMarketplaceVisible && !ids.contains(p.id));
      return [...remote, ...extras];
    } catch (_) {
      return (await _fallback.fetchProducts()).where((p) => p.isMarketplaceVisible).toList();
    }
  }

  Product _hydrateSeed(Product remote) {
    final mock = MockCatalog.byId(remote.id);
    if (mock == null) return remote;
    if (remote.searchKeywords.isNotEmpty && remote.hasValidPrimaryImage) return remote;
    return remote.copyWith(
      images: mock.images,
      imageUrls: mock.displayImageUrls,
      searchKeywords: mock.searchKeywords,
      subcategory: mock.subcategory,
    );
  }

  @override
  Future<List<Product>> fetchProducts() => _marketplace();

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    if (!MazonnFirebase.isReady) return _fallback.fetchCategories();
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (snapshot.docs.isEmpty) return await _fallback.fetchCategories();
      final byId = {for (final c in MockCatalog.categories) c.id: c};
      return snapshot.docs.map((doc) {
        final data = {...doc.data(), 'id': doc.data()['id'] ?? doc.id};
        final mock = byId[data['id']];
        return ProductCategory.fromJson(
          data,
          icon: mock?.icon ?? Icons.category_outlined,
          tone: mock?.tone ?? const Color(0xFFD8C4B0),
        );
      }).toList();
    } catch (_) {
      return await _fallback.fetchCategories();
    }
  }

  @override
  Future<List<PromoBanner>> fetchBanners() => _fallback.fetchBanners();

  @override
  Future<Product?> fetchById(String id) async {
    if (!MazonnFirebase.isReady) return _fallback.fetchById(id);
    final doc = await _products.doc(id).get();
    if (doc.exists && doc.data() != null) return _hydrateSeed(Product.fromJson(doc.data()!));
    return MockCatalog.byId(id);
  }

  @override
  Future<List<Review>> fetchReviews(String productId) => _fallback.fetchReviews(productId);

  @override
  Future<List<Product>> search(String query, SearchFilters filters) async {
    return applyCatalogSearch(await _marketplace(), query, filters);
  }

  @override
  Future<List<Product>> fetchVendorProducts(String vendorId) async {
    if (!MazonnFirebase.isReady) return _fallback.fetchVendorProducts(vendorId);
    final snapshot = await _products.where('vendorId', isEqualTo: vendorId).get();
    if (snapshot.docs.isEmpty) return _fallback.fetchVendorProducts(vendorId);
    return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
  }

  @override
  Future<void> upsertProduct(Product product) async {
    if (!MazonnFirebase.isReady) return;
    final payload = Map<String, dynamic>.from(product.toJson());
    try {
      final vendorSnap = await FirebaseFirestore.instance.collection('vendors').doc(product.vendorId).get();
      final vendorStatus = vendorSnap.data()?['approvalStatus'] as String? ?? product.vendorApprovalStatus;
      payload['vendorApprovalStatus'] = vendorStatus;
      if (vendorStatus != 'approved' &&
          (product.moderation == ProductModeration.pending || product.moderation == ProductModeration.approved)) {
        throw StateError('Your vendor account must be approved before you can publish products.');
      }
    } catch (e) {
      if (e is StateError) rethrow;
    }
    await _products.doc(product.id).set(payload);
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (!MazonnFirebase.isReady) return;
    await _products.doc(id).delete();
  }
}
