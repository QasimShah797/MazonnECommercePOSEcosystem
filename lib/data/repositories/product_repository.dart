import '../../models/catalog_extras.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/review.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<List<ProductCategory>> fetchCategories();
  Future<List<PromoBanner>> fetchBanners();
  Future<Product?> fetchById(String id);
  Future<List<Review>> fetchReviews(String productId);
  Future<List<Product>> search(String query, SearchFilters filters);
  Future<List<Product>> fetchVendorProducts(String vendorId);
  Future<void> upsertProduct(Product product);
  Future<void> deleteProduct(String id);
}
