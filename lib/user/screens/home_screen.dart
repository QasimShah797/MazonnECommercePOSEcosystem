import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../shared/widgets/mazonn_visual.dart';
import '../../../shared/widgets/product_card.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/wishlist_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final user = context.watch<AuthController>().user;
    final cart = context.watch<CartController>();
    final wishlist = context.watch<WishlistController>();

    if (catalog.loading && catalog.products.isEmpty) {
      return const Scaffold(body: LoadingState(label: 'Preparing your edit'));
    }
    if (catalog.error != null && catalog.products.isEmpty) {
      return Scaffold(body: ErrorState(message: catalog.error!, onRetry: catalog.load));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 12, MazonnSpacing.page, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${MazonnFormatters.greeting(DateTime.now())}, ${user?.firstName ?? 'there'}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: MazonnColors.goldDark),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  user?.city ?? AppConstants.defaultCity,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconBadgeButton(
                      icon: Icons.favorite_border,
                      count: wishlist.ids.length,
                      onPressed: () => context.push('/shop/wishlist'),
                    ),
                    IconBadgeButton(
                      icon: Icons.notifications_none_outlined,
                      count: context.watch<NotificationController>().unreadCount,
                      onPressed: () => context.push('/shop/notifications'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 18, MazonnSpacing.page, 8),
                child: GestureDetector(
                  onTap: () => context.push('/shop/search'),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: MazonnColors.white,
                      borderRadius: MazonnRadius.pillAll,
                      border: Border.all(color: MazonnColors.linen),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: MazonnColors.stone),
                        SizedBox(width: 10),
                        Text('Search Mazonn'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _BannerCarousel(catalog: catalog)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Categories',
                action: 'See all',
                onAction: () => context.go('/shop/categories'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: MazonnSpacing.page),
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final cat = catalog.categories[i];
                    return InkWell(
                      onTap: () => context.push('/shop/category/${cat.id}'),
                      borderRadius: MazonnRadius.card,
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          color: cat.tone.withValues(alpha: 0.55),
                          borderRadius: MazonnRadius.card,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, color: MazonnColors.ink),
                            const SizedBox(height: 8),
                            Text(cat.name, style: Theme.of(context).textTheme.labelLarge),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            _horizontalProducts(context, 'Flash sale', catalog.flashSale, cart, wishlist),
            _horizontalProducts(context, 'Featured', catalog.featured, cart, wishlist),
            _horizontalProducts(context, 'Popular', catalog.popular, cart, wishlist),
            _horizontalProducts(context, 'New arrivals', catalog.newArrivals, cart, wishlist),
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Recommended for you'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 0, MazonnSpacing.page, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = catalog.recommended[i];
                    return _card(context, product, cart, wishlist);
                  },
                  childCount: catalog.recommended.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _horizontalProducts(
    BuildContext context,
    String title,
    List<Product> products,
    CartController cart,
    WishlistController wishlist,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SectionHeader(title: title),
          SizedBox(
            height: 292,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: MazonnSpacing.page),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _card(context, products[i], cart, wishlist, width: 168),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    Product product,
    CartController cart,
    WishlistController wishlist, {
    double? width,
  }) {
    return ProductCard(
      product: product,
      width: width,
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
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.catalog});
  final CatalogController catalog;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.catalog.banners;
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final banner = banners[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 12, MazonnSpacing.page, 0),
                child: ClipRRect(
                  borderRadius: MazonnRadius.card,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MazonnVisual(
                        seed: banner.seed,
                        categoryId: i == 1 ? 'home' : 'fashion',
                        monogram: '',
                        borderRadius: BorderRadius.zero,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.eyebrow.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                            ),
                            const Spacer(),
                            Text(
                              banner.subtitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _index ? MazonnColors.noir : MazonnColors.linen,
                borderRadius: MazonnRadius.pillAll,
              ),
            );
          }),
        ),
      ],
    );
  }
}
