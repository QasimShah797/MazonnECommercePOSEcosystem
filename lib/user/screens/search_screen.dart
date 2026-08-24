import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../models/catalog_extras.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/catalog_controller.dart';
import 'categories_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  SearchFilters _filters = const SearchFilters();
  List<Product> _results = [];
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final catalog = context.read<CatalogController>();
    setState(() => _loading = true);
    final results = await catalog.search(_query.text, _filters);
    await catalog.addRecentSearch(_query.text);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search Mazonn',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onSubmitted: (_) => _run(),
        ),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState(label: 'Searching')
          : _searched
              ? _results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'Try a different word, or loosen the filters.',
                    )
                  : ProductGrid(products: _results)
              : ListView(
                  padding: const EdgeInsets.all(MazonnSpacing.page),
                  children: [
                    Row(
                      children: [
                        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        if (catalog.recentSearches.isNotEmpty)
                          TextButton(
                            onPressed: catalog.clearRecentSearches,
                            child: const Text('Clear'),
                          ),
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
                                onPressed: () {
                                  _query.text = e;
                                  _run();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    Text('Popular searches', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: MockCatalog.popularSearches
                          .map(
                            (e) => ActionChip(
                              label: Text(e),
                              onPressed: () {
                                _query.text = e;
                                _run();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
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
      if (_searched || _query.text.isNotEmpty) _run();
    }
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
            values: RangeValues(_filters.minPrice, _filters.maxPrice),
            max: 400,
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
