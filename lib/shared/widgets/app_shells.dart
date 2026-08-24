import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';
import '../../user/controllers/cart_controller.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().itemCount;
    const destinations = [
      (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
      (icon: Icons.grid_view_outlined, selected: Icons.grid_view_rounded, label: 'Categories'),
      (icon: Icons.shopping_bag_outlined, selected: Icons.shopping_bag_rounded, label: 'Cart'),
      (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long_rounded, label: 'Orders'),
      (icon: Icons.person_outline, selected: Icons.person, label: 'Profile'),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: MazonnColors.white,
          boxShadow: MazonnShadows.nav,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(destinations.length, (i) {
                final dest = destinations[i];
                final selected = navigationShell.currentIndex == i;
                return Expanded(
                  child: InkWell(
                    borderRadius: MazonnRadius.pillAll,
                    onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Badge(
                            isLabelVisible: i == 2 && cartCount > 0,
                            backgroundColor: MazonnColors.gold,
                            label: Text('$cartCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                            child: Icon(
                              selected ? dest.selected : dest.icon,
                              color: selected ? MazonnColors.noir : MazonnColors.stoneLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: selected ? MazonnColors.noir : MazonnColors.stoneLight,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (icon: Icons.dashboard_outlined, selected: Icons.dashboard_rounded, label: 'Dashboard'),
      (icon: Icons.inventory_2_outlined, selected: Icons.inventory_2_rounded, label: 'Products'),
      (icon: Icons.local_shipping_outlined, selected: Icons.local_shipping_rounded, label: 'Orders'),
      (icon: Icons.insights_outlined, selected: Icons.insights_rounded, label: 'Analytics'),
      (icon: Icons.storefront_outlined, selected: Icons.storefront_rounded, label: 'Profile'),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(color: MazonnColors.white, boxShadow: MazonnShadows.nav),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(destinations.length, (i) {
                final dest = destinations[i];
                final selected = navigationShell.currentIndex == i;
                return Expanded(
                  child: InkWell(
                    borderRadius: MazonnRadius.pillAll,
                    onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? dest.selected : dest.icon,
                            color: selected ? MazonnColors.noir : MazonnColors.stoneLight,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest.label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: selected ? MazonnColors.noir : MazonnColors.stoneLight,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
