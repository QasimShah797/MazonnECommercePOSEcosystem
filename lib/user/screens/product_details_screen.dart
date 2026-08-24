import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/review.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../shared/widgets/mazonn_visual.dart';
import '../../../shared/widgets/product_card.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/wishlist_controller.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _image = 0;
  int _qty = 1;
  String? _color;
  String? _size;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reviews = await context.read<CatalogController>().reviewsFor(widget.productId);
      if (mounted) setState(() => _reviews = reviews);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final product = catalog.byId(widget.productId);
    if (product == null) {
      return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Not found', message: 'This piece is no longer available.'));
    }
    final wishlist = context.watch<WishlistController>();
    final cart = context.watch<CartController>();
    final related = catalog.related(product);
    _color ??= product.colors.isNotEmpty ? product.colors.first : null;
    _size ??= product.sizes.isNotEmpty ? product.sizes.first : null;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => wishlist.toggle(product.id),
            icon: Icon(wishlist.contains(product.id) ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 360,
                  child: PageView.builder(
                    itemCount: 3,
                    onPageChanged: (i) => setState(() => _image = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MazonnVisual(
                        seed: product.visualSeed + i,
                        categoryId: product.categoryId,
                        monogram: product.brand.substring(0, 1),
                        borderRadius: BorderRadius.circular(MazonnRadius.lg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _image ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _image ? MazonnColors.noir : MazonnColors.linen,
                        borderRadius: MazonnRadius.pillAll,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: product.badges.map((b) => ProductBadge(label: b)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(product.brand.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: MazonnColors.gold),
                          const SizedBox(width: 4),
                          Text('${product.rating}  ·  ${product.reviewCount} reviews'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(MazonnFormatters.money(product.price), style: Theme.of(context).textTheme.headlineSmall),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              MazonnFormatters.money(product.originalPrice!),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: MazonnColors.stoneLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(color: MazonnColors.error, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                      if (product.colors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Color', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.colors
                              .map(
                                (c) => ChoiceChip(
                                  label: Text(c),
                                  selected: _color == c,
                                  onSelected: (_) => setState(() => _color = c),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Size', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.sizes
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _size == s,
                                  onSelected: (_) => setState(() => _size = s),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Quantity'),
                          const Spacer(),
                          QuantitySelector(value: _qty, onChanged: (v) => setState(() => _qty = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InfoTile(
                        icon: Icons.storefront_outlined,
                        title: product.vendorName,
                        subtitle: 'Ships from the atelier · Typically 1–2 days to dispatch',
                      ),
                      const SizedBox(height: 8),
                      const _InfoTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'Delivery',
                        subtitle: 'Standard 3–5 days · Express 1–2 days · Free over \$120',
                      ),
                      if (product.specifications.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Specifications', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...product.specifications.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
                                Text(e.value, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._reviews.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.author}  ·  ${r.rating.toStringAsFixed(0)}★', style: Theme.of(context).textTheme.titleSmall),
                              Text(r.title, style: Theme.of(context).textTheme.bodyMedium),
                              Text(r.body, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      if (related.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Related pieces', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 292,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: related.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final p = related[i];
                              return ProductCard(
                                product: p,
                                width: 160,
                                wishlisted: wishlist.contains(p.id),
                                onTap: () => context.push('/shop/product/${p.id}'),
                                onWishlist: () => wishlist.toggle(p.id),
                                onAdd: () => cart.add(p),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: MazonnButton(
                      label: 'Add to bag',
                      tone: MazonnButtonTone.outline,
                      onPressed: () {
                        cart.add(product, quantity: _qty, color: _color, size: _size);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to bag')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MazonnButton(
                      label: 'Buy now',
                      onPressed: () {
                        cart.add(product, quantity: _qty, color: _color, size: _size);
                        context.push('/shop/checkout');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MazonnColors.white,
        borderRadius: MazonnRadius.card,
      ),
      child: Row(
        children: [
          Icon(icon, color: MazonnColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
