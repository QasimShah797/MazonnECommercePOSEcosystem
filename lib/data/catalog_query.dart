import '../models/catalog_extras.dart';
import '../models/product.dart';
import '../services/search_service.dart';
import 'mock/mock_catalog.dart';

List<Product> applyCatalogSearch(List<Product> source, String query, SearchFilters filters) {
  return mazonnSearch.search(
    catalog: source,
    query: query,
    filters: filters,
    categories: MockCatalog.categories,
  );
}
