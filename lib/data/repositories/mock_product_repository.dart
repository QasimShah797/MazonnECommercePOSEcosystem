import '../../core/constants/app_constants.dart';
import '../../models/catalog_extras.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../catalog_query.dart';
import '../mock/mock_catalog.dart';
import 'product_repository.dart';

class MockProductRepository implements ProductRepository {
  Future<void> _delay() => Future<void>.delayed(AppConstants.mockNetworkDelay);

  @override
  Future<List<Product>> fetchProducts() async {
    await _delay();
    return List<Product>.from(MockCatalog.products);
  }

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    await _delay();
    return MockCatalog.categories;
  }

  @override
  Future<List<PromoBanner>> fetchBanners() async {
    await _delay();
    return MockCatalog.banners;
  }

  @override
  Future<Product?> fetchById(String id) async {
    await _delay();
    return MockCatalog.byId(id);
  }

  @override
  Future<List<Review>> fetchReviews(String productId) async {
    await _delay();
    final specific = MockCatalog.reviews.where((r) => r.productId == productId).toList();
    if (specific.isNotEmpty) return specific;
    return [
      Review(
        id: 'generic-$productId',
        productId: productId,
        author: 'Mazonn member',
        rating: 5,
        title: 'As described',
        body: 'Thoughtful packaging and a piece I will keep for years.',
        createdAt: DateTime(2026, 8, 1),
      ),
    ];
  }

  @override
  Future<List<Product>> search(String query, SearchFilters filters) async {
    await _delay();
    return applyCatalogSearch(MockCatalog.products, query, filters);
  }

  @override
  Future<List<Product>> fetchVendorProducts(String vendorId) async {
    await _delay();
    final owned = MockCatalog.products.where((p) => p.vendorId == vendorId).toList();
    return owned.isEmpty ? List<Product>.from(MockCatalog.products) : owned;
  }

  @override
  Future<void> upsertProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String id) async {}
}
