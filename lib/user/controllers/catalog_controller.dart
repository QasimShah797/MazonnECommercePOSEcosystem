import 'package:flutter/foundation.dart' hide Category;

import '../../data/repositories/product_repository.dart';
import '../../models/catalog_extras.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/session_service.dart';

class CatalogController extends ChangeNotifier {
  CatalogController({
    required ProductRepository repository,
    required SessionService session,
  })  : _repository = repository,
        _session = session;

  final ProductRepository _repository;
  final SessionService _session;

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<PromoBanner> _banners = [];
  List<String> _recentSearches = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products.where((p) => p.isActive).toList();
  List<ProductCategory> get categories => _categories;
  List<PromoBanner> get banners => _banners;
  List<String> get recentSearches => _recentSearches;
  bool get loading => _loading;
  String? get error => _error;

  List<Product> get featured => products.where((p) => p.isFeatured).toList();
  List<Product> get popular => products.where((p) => p.isPopular).toList();
  List<Product> get newArrivals => products.where((p) => p.isNewArrival).toList();
  List<Product> get recommended => products.where((p) => p.isRecommended).toList();
  List<Product> get flashSale => products.where((p) => p.isFlashSale).toList();

  Product? byId(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProductCategory? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> byCategory(String id) => products.where((p) => p.categoryId == id).toList();

  List<Product> related(Product product) =>
      products.where((p) => p.categoryId == product.categoryId && p.id != product.id).take(8).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchProducts(),
        _repository.fetchCategories(),
        _repository.fetchBanners(),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<ProductCategory>;
      _banners = results[2] as List<PromoBanner>;
      _recentSearches = _session.readRecentSearches();
    } catch (_) {
      _error = 'Unable to load the catalog right now.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> search(String query, SearchFilters filters) {
    return _repository.search(query, filters);
  }

  Future<List<Review>> reviewsFor(String productId) => _repository.fetchReviews(productId);

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches = _recentSearches.take(8).toList();
    }
    await _session.writeRecentSearches(_recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    await _session.writeRecentSearches(_recentSearches);
    notifyListeners();
  }
}
