import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../shared/widgets/product_card.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/wishlist_controller.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Categories', automaticallyImplyLeading: false),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 8, MazonnSpacing.page, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: catalog.categories.length,
        itemBuilder: (context, i) {
          final cat = catalog.categories[i];
          final count = catalog.byCategory(cat.id).length;
          return InkWell(
            onTap: () => context.push('/shop/category/${cat.id}'),
            borderRadius: MazonnRadius.card,
            child: Ink(
              decoration: BoxDecoration(
                color: cat.tone.withValues(alpha: 0.45),
                borderRadius: MazonnRadius.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(cat.icon, size: 28, color: MazonnColors.ink),
                    const Spacer(),
                    Text(cat.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(cat.subtitle, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('$count pieces', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final category = catalog.categoryById(categoryId);
    final products = catalog.byCategory(categoryId);
    return Scaffold(
      appBar: MazonnAppBar(title: category?.name ?? 'Collection'),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing here yet',
              message: 'This collection will fill as makers join Mazonn.',
            )
          : ProductGrid(products: products),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final wishlist = context.watch<WishlistController>();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 8, MazonnSpacing.page, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.56,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final product = products[i];
        return ProductCard(
          product: product,
          wishlisted: wishlist.contains(product.id),
          onTap: () => context.push('/shop/product/${product.id}'),
          onWishlist: () => wishlist.toggle(product.id),
          onAdd: () {
            cart.add(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} added to bag')),
            );
          },
        );
      },
    );
  }
}
