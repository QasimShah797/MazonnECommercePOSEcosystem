import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_image.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/cart_controller.dart';
import '../controllers/wishlist_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final wishlist = context.watch<WishlistController>();

    return Scaffold(
      appBar: const MazonnAppBar(title: 'Bag', automaticallyImplyLeading: false),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your bag is empty',
              message: 'When you find something you love, it will wait here.',
              actionLabel: 'Browse Mazonn',
              onAction: () => context.go('/shop'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MazonnColors.white,
                          borderRadius: MazonnRadius.card,
                          boxShadow: MazonnShadows.soft,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 88,
                              height: 104,
                              child: MazonnImage.product(item.product),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                                  Text(
                                    [
                                      item.selectedColor,
                                      item.selectedSize,
                                    ].whereType<String>().join(' · '),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(MazonnFormatters.money(item.lineTotal), style: Theme.of(context).textTheme.titleSmall),
                                  if (item.bulkDiscount > 0)
                                    Text('Bulk save ${MazonnFormatters.money(item.bulkDiscount)}', style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      QuantitySelector(
                                        value: item.quantity,
                                        onChanged: (v) => cart.setQuantity(item.variantKey, v),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => wishlist.toggle(item.product.id),
                                        icon: Icon(
                                          wishlist.contains(item.product.id) ? Icons.favorite : Icons.favorite_border,
                                          size: 20,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => cart.remove(item.variantKey),
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: const BoxDecoration(color: MazonnColors.white, boxShadow: MazonnShadows.nav),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Column(
                      children: [
                        _row(context, 'Subtotal', MazonnFormatters.money(cart.merchandiseSubtotal)),
                        _row(context, 'Bulk discount', MazonnFormatters.money(cart.bulkDiscount)),
                        _row(context, 'Delivery from', MazonnFormatters.money(cart.deliveryFee(false))),
                        const Divider(height: 20),
                        _row(context, 'Total', MazonnFormatters.money(cart.total(express: false)), strong: true),
                        const SizedBox(height: 12),
                        MazonnButton(label: 'Checkout', onPressed: () => context.push('/shop/checkout')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool strong = false}) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
