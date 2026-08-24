import '../../models/catalog_extras.dart';
import '../../models/product.dart';

List<Product> applyCatalogSearch(List<Product> source, String query, SearchFilters filters) {
  var results = source.where((p) => p.isActive).toList();
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    results = results
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.categoryId.toLowerCase().contains(q),
        )
        .toList();
  }
  if (filters.categoryId != null) {
    results = results.where((p) => p.categoryId == filters.categoryId).toList();
  }
  results = results
      .where((p) => p.price >= filters.minPrice && p.price <= filters.maxPrice)
      .where((p) => p.rating >= filters.minRating)
      .toList();
  if (filters.onSaleOnly) {
    results = results.where((p) => p.discountPercent > 0).toList();
  }
  if (filters.inStockOnly) {
    results = results.where((p) => p.inStock).toList();
  }
  switch (filters.sort) {
    case ProductSort.priceLow:
      results.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.priceHigh:
      results.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.rating:
      results.sort((a, b) => b.rating.compareTo(a.rating));
    case ProductSort.newest:
      results.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
    case ProductSort.relevance:
      break;
  }
  return results;
}
