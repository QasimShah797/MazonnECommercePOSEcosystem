import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../models/catalog_extras.dart';
import '../../../models/product.dart';
import '../../../services/search_service.dart';
import '../../../shared/widgets/mazonn_image.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/catalog_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  SearchFilters _filters = const SearchFilters();
  List<Product> _results = [];
  List<SearchSuggestion> _suggestions = [];
  bool _searched = false;
  bool _loading = false;
  int _visible = LocalCatalogSearchService.pageSize;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: LocalCatalogSearchService.debounceMs), () {
      if (!mounted) return;
      _preview(value);
    });
  }

  Future<void> _preview(String raw) async {
    final catalog = context.read<CatalogController>();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        if (!_searched) _results = [];
      });
      return;
    }
    final suggestions = mazonnSearch.suggest(
      catalog: catalog.products,
      query: q,
      categories: catalog.categories,
    );
    final results = await catalog.search(q, _filters);
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _results = results;
      _searched = true;
      _visible = LocalCatalogSearchService.pageSize;
      _loading = false;
    });
  }

  Future<void> _run({String? value, bool record = true}) async {
    final catalog = context.read<CatalogController>();
    final q = (value ?? _query.text).trim();
    if (value != null) _query.text = value;
    setState(() => _loading = true);
    final results = await catalog.search(q, _filters);
    if (record && q.isNotEmpty) await catalog.addRecentSearch(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
      _loading = false;
      _visible = LocalCatalogSearchService.pageSize;
      _suggestions = q.length < 2
          ? []
          : mazonnSearch.suggest(catalog: catalog.products, query: q, categories: catalog.categories);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _query.clear();
    setState(() {
      _results = [];
      _suggestions = [];
      _searched = false;
      _loading = false;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final visible = _results.take(_visible).toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search products, brands and categories',
            prefixIcon: Icon(Icons.search_rounded),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _run(),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(onPressed: _clear, icon: const Icon(Icons.close_rounded), tooltip: 'Clear search'),
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: _loading
          ? const LoadingState(label: 'Searching')
          : _searched
              ? _buildResults(context, catalog, visible)
              : _buildIdle(context, catalog),
    );
  }

  Widget _buildIdle(BuildContext context, CatalogController catalog) {
    return ListView(
      padding: const EdgeInsets.all(MazonnSpacing.page),
      children: [
        Row(
          children: [
            Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (catalog.recentSearches.isNotEmpty)
              TextButton(onPressed: catalog.clearRecentSearches, child: const Text('Clear')),
          ],
        ),
        if (catalog.recentSearches.isEmpty)
          Text('Your recent searches will appear here.', style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: 8,
            children: catalog.recentSearches
                .map(
                  (e) => ActionChip(
                    label: Text(e),
                    onPressed: () => _run(value: e),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 24),
        Text('Popular searches', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: {
            ...mazonnSearch.synonyms.popular,
            ...MockCatalog.popularSearches,
          }.map((e) => ActionChip(label: Text(e), onPressed: () => _run(value: e))).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, CatalogController catalog, List<Product> visible) {
    if (_results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(MazonnSpacing.page),
        children: [
          const EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            message: 'Try a related word, check the spelling, or browse popular searches.',
          ),
          const SizedBox(height: 8),
          Text('Try these', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MockCatalog.popularSearches
                .map((e) => ActionChip(label: Text(e), onPressed: () => _run(value: e)))
                .toList(),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 8, MazonnSpacing.page, 24),
      children: [
        if (_suggestions.isNotEmpty) ...[
          Text('Search suggestions', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s.label),
                    onPressed: () => _run(value: s.query),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        Text('Products', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...visible.map((product) => _SearchProductTile(product: product)),
        if (_results.length > _visible)
          TextButton(
            onPressed: () => setState(() => _visible += LocalCatalogSearchService.pageSize),
            child: Text('Show more (${_results.length - _visible} remaining)'),
          ),
      ],
    );
  }

  Future<void> _openFilters() async {
    final catalog = context.read<CatalogController>();
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(filters: _filters, categories: catalog.categories.map((e) => e.id).toList()),
    );
    if (result != null) {
      setState(() => _filters = result);
      if (_searched || _query.text.isNotEmpty) _run(record: false);
    }
  }
}

class _SearchProductTile extends StatelessWidget {
  const _SearchProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: SizedBox(
        width: 64,
        height: 64,
        child: MazonnImage.product(product, borderRadius: BorderRadius.circular(8)),
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${product.vendorName} · ${product.brand}'),
      trailing: Text(MazonnFormatters.money(product.price), style: Theme.of(context).textTheme.titleSmall),
      onTap: () => context.push('/shop/product/${product.id}'),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filters, required this.categories});
  final SearchFilters filters;
  final List<String> categories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text('Price  \$${_filters.minPrice.round()} – \$${_filters.maxPrice.round()}'),
          RangeSlider(
            values: RangeValues(_filters.minPrice, _filters.maxPrice.clamp(0, 1200)),
            max: 1200,
            activeColor: MazonnColors.noir,
            onChanged: (v) => setState(() => _filters = _filters.copyWith(minPrice: v.start, maxPrice: v.end)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filters.categoryId == null,
                onSelected: (_) => setState(() => _filters = _filters.copyWith(clearCategory: true)),
              ),
              ...widget.categories.map(
                (id) => FilterChip(
                  label: Text(id[0].toUpperCase() + id.substring(1)),
                  selected: _filters.categoryId == id,
                  onSelected: (_) => setState(() => _filters = _filters.copyWith(categoryId: id)),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('On sale'),
            value: _filters.onSaleOnly,
            onChanged: (v) => setState(() => _filters = _filters.copyWith(onSaleOnly: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In stock'),
            value: _filters.inStockOnly,
            onChanged: (v) => setState(() => _filters = _filters.copyWith(inStockOnly: v)),
          ),
          DropdownButtonFormField<ProductSort>(
            initialValue: _filters.sort,
            decoration: const InputDecoration(labelText: 'Sort'),
            items: ProductSort.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(switch (s) {
                      ProductSort.relevance => 'Relevance',
                      ProductSort.priceLow => 'Price: low to high',
                      ProductSort.priceHigh => 'Price: high to low',
                      ProductSort.rating => 'Top rated',
                      ProductSort.newest => 'Newest',
                    }),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _filters = _filters.copyWith(sort: v));
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _filters),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
