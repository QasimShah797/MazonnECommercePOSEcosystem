import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<List<Product>> _all() async {
    if (!MazonnFirebase.isReady) return _fallback.fetchProducts();
    await MazonnFirebase.seedCatalogIfNeeded();
    final snapshot = await _products.get();
    if (snapshot.docs.isEmpty) return _fallback.fetchProducts();
    return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
  }

  @override
  Future<List<Product>> fetchProducts() => _all();

  @override
  Future<List<ProductCategory>> fetchCategories() => _fallback.fetchCategories();

  @override
  Future<List<PromoBanner>> fetchBanners() => _fallback.fetchBanners();

  @override
  Future<Product?> fetchById(String id) async {
    if (!MazonnFirebase.isReady) return _fallback.fetchById(id);
    final doc = await _products.doc(id).get();
    if (doc.exists && doc.data() != null) return Product.fromJson(doc.data()!);
    return MockCatalog.byId(id);
  }

  @override
  Future<List<Review>> fetchReviews(String productId) => _fallback.fetchReviews(productId);

  @override
  Future<List<Product>> search(String query, SearchFilters filters) async {
    return applyCatalogSearch(await _all(), query, filters);
  }

  @override
  Future<List<Product>> fetchVendorProducts(String vendorId) async {
    final all = await _all();
    return all.where((p) => p.vendorId == vendorId).toList();
  }

  @override
  Future<void> upsertProduct(Product product) async {
    if (!MazonnFirebase.isReady) return;
    await _products.doc(product.id).set(product.toJson());
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (!MazonnFirebase.isReady) return;
    await _products.doc(id).delete();
  }
}
