import '../models/catalog_extras.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../data/search/search_synonyms.dart';

class SearchSuggestion {
  const SearchSuggestion({required this.label, required this.query, this.kind = SearchSuggestionKind.term});

  final String label;
  final String query;
  final SearchSuggestionKind kind;
}

enum SearchSuggestionKind { term, category, product, synonym }

class SearchPage {
  const SearchPage({required this.items, required this.total, this.suggestions = const []});

  final List<Product> items;
  final int total;
  final List<SearchSuggestion> suggestions;

  bool get hasMore => items.length < total;
}

/// Local ranked search. Swap this implementation for Elasticsearch/Algolia later
/// without changing catalog UI or repositories.
abstract class SearchService {
  List<Product> search({
    required List<Product> catalog,
    required String query,
    SearchFilters filters = const SearchFilters(),
    List<ProductCategory> categories = const [],
  });

  List<SearchSuggestion> suggest({
    required List<Product> catalog,
    required String query,
    List<ProductCategory> categories = const [],
    int limit = 8,
  });

  Set<String> expand(String query);

  SearchSynonymTable get synonyms;
  void replaceSynonyms(SearchSynonymTable table);
}

class LocalCatalogSearchService implements SearchService {
  LocalCatalogSearchService({SearchSynonymTable? synonyms}) : _synonyms = synonyms ?? SearchSynonymTable.defaults();

  SearchSynonymTable _synonyms;
  final Map<String, List<SearchSuggestion>> _suggestionCache = {};

  static const debounceMs = 300;
  static const pageSize = 20;

  @override
  SearchSynonymTable get synonyms => _synonyms;

  @override
  void replaceSynonyms(SearchSynonymTable table) {
    _synonyms = table;
    _suggestionCache.clear();
  }

  @override
  Set<String> expand(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return {};
    final out = <String>{normalized};
    for (final token in _tokens(normalized)) {
      out.add(token);
      final mapped = _synonyms.aliases[token];
      if (mapped != null) out.addAll(mapped.map(normalize));
      for (final entry in _synonyms.aliases.entries) {
        if (entry.value.map(normalize).contains(token) || entry.key == token) {
          out.add(entry.key);
          out.addAll(entry.value.map(normalize));
        }
      }
    }
    return out.where((e) => e.isNotEmpty).toSet();
  }

  @override
  List<Product> search({
    required List<Product> catalog,
    required String query,
    SearchFilters filters = const SearchFilters(),
    List<ProductCategory> categories = const [],
  }) {
    var results = catalog.where((p) => p.isActive).toList();
    final q = normalize(query);
    if (_synonyms.blocked.contains(q)) return [];

    if (q.isNotEmpty) {
      final expanded = expand(q);
      final scored = <({Product product, int score})>[];
      for (final product in results) {
        final score = _score(product, q, expanded, categories);
        if (score > 0) scored.add((product: product, score: score));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      results = scored.map((e) => e.product).toList();
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

  @override
  List<SearchSuggestion> suggest({
    required List<Product> catalog,
    required String query,
    List<ProductCategory> categories = const [],
    int limit = 8,
  }) {
    final q = normalize(query);
    if (q.length < 2) return const [];
    final cached = _suggestionCache[q];
    if (cached != null) return cached.take(limit).toList();

    final expanded = expand(q);
    final seen = <String>{};
    final out = <SearchSuggestion>[];

    void add(SearchSuggestion suggestion) {
      final key = suggestion.label.toLowerCase();
      if (seen.contains(key) || suggestion.label.trim().isEmpty) return;
      seen.add(key);
      out.add(suggestion);
    }

    for (final entry in _synonyms.aliases.entries) {
      if (entry.key.startsWith(q) || q.startsWith(entry.key)) {
        add(SearchSuggestion(label: _title(entry.key), query: entry.key, kind: SearchSuggestionKind.synonym));
      }
      for (final alias in entry.value) {
        final n = normalize(alias);
        if (n.startsWith(q) || entry.key.startsWith(q)) {
          add(SearchSuggestion(label: _title(alias), query: alias, kind: SearchSuggestionKind.synonym));
        }
      }
    }

    for (final category in categories) {
      if (category.name.toLowerCase().startsWith(q) || category.id.startsWith(q)) {
        add(SearchSuggestion(label: category.name, query: category.name, kind: SearchSuggestionKind.category));
      }
    }

    final ranked = search(catalog: catalog, query: q);
    for (final product in ranked) {
      add(SearchSuggestion(label: product.name, query: product.name, kind: SearchSuggestionKind.product));
      for (final keyword in product.searchKeywords) {
        if (normalize(keyword).startsWith(q) && keyword.length > 2) {
          add(SearchSuggestion(label: _title(keyword), query: keyword, kind: SearchSuggestionKind.term));
        }
      }
      if (out.length >= 24) break;
    }

    for (final token in expanded) {
      if (token.startsWith(q) || q.startsWith(token.substring(0, token.length.clamp(1, q.length)))) {
        add(SearchSuggestion(label: _title(token), query: token, kind: SearchSuggestionKind.term));
      }
    }

    _suggestionCache[q] = out;
    return out.take(limit).toList();
  }

  int _score(Product product, String q, Set<String> expanded, List<ProductCategory> categories) {
    final name = product.name.toLowerCase();
    final brand = product.brand.toLowerCase();
    final desc = product.description.toLowerCase();
    final sub = product.subcategory.toLowerCase();
    final cat = product.categoryId.toLowerCase();
    final keywords = product.searchKeywords.map(normalize).toSet();
    var best = 0;

    if (name == q) best = 1000;
    for (final t in expanded) {
      if (name == t) best = _max(best, 980);
    }
    if (q.length >= 2 && name.startsWith(q)) best = _max(best, 900);
    for (final t in expanded) {
      if (t.length >= 2 && _hasToken(name, t)) best = _max(best, 820);
      if (t.length >= 2 && name.startsWith(t)) best = _max(best, 860);
    }

    for (final t in expanded) {
      if (sub.isNotEmpty && (sub == t || _hasToken(sub, t) || (t.length >= 4 && sub.contains(t)))) {
        best = _max(best, 720);
      }
    }

    final categoryNames = {
      for (final c in categories) c.id: c.name.toLowerCase(),
    };
    final catName = categoryNames[product.categoryId] ?? cat;
    if (expanded.contains(cat) || expanded.contains(catName) || q == cat || q == catName) {
      best = _max(best, 640);
    }

    if (_hasToken(brand, q) || expanded.any((t) => t.length >= 3 && _hasToken(brand, t))) {
      best = _max(best, 600);
    }

    for (final t in expanded) {
      if (t.length < 2) continue;
      if (keywords.contains(t) || keywords.any((k) => k == t || _hasToken(k, t))) {
        best = _max(best, 520);
      }
    }

    for (final t in expanded) {
      if (t.length >= 4 && _hasToken(desc, t)) best = _max(best, 320);
    }

    for (final token in [..._tokens(name), ...keywords, brand]) {
      if (token.length < 4 || q.length < 3) continue;
      final distance = levenshtein(q, token);
      if (distance <= 2) best = _max(best, 250 - distance * 20);
      for (final t in expanded) {
        if (t.length >= 4) {
          final d = levenshtein(t, token);
          if (d <= 2) best = _max(best, 230 - d * 20);
        }
      }
    }
    return best;
  }

  static String normalize(String raw) => raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static Iterable<String> _tokens(String value) =>
      value.split(RegExp(r'[^a-z0-9+]+')).where((t) => t.isNotEmpty);

  static bool _hasToken(String haystack, String needle) {
    if (needle.contains(' ')) return haystack.contains(needle);
    return RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(haystack);
  }

  static int _max(int a, int b) => a > b ? a : b;

  static String _title(String value) {
    if (value.toLowerCase() == 'tv' || value.toLowerCase() == 'iphone') {
      return value.toLowerCase() == 'tv' ? 'TV' : 'iPhone';
    }
    return value.split(' ').map((w) {
      if (w.isEmpty) return w;
      if (w == 'tv' || w == 'iphone') return w == 'tv' ? 'TV' : 'iPhone';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final v0 = List<int>.generate(b.length + 1, (i) => i);
    final v1 = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        final insert = v1[j] + 1;
        final delete = v0[j + 1] + 1;
        final replace = v0[j] + cost;
        var min = insert < delete ? insert : delete;
        if (replace < min) min = replace;
        v1[j + 1] = min;
      }
      for (var j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[b.length];
  }
}

final SearchService mazonnSearch = LocalCatalogSearchService();
