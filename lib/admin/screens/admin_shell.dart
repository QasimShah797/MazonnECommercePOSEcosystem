import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../shared/controllers/auth_controller.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const destinations = [
    ('/admin', Icons.dashboard_outlined, 'Dashboard'),
    ('/admin/vendors', Icons.storefront_outlined, 'Vendors'),
    ('/admin/products', Icons.inventory_2_outlined, 'Products'),
    ('/admin/categories', Icons.category_outlined, 'Categories'),
    ('/admin/brands', Icons.sell_outlined, 'Brands'),
    ('/admin/orders', Icons.local_shipping_outlined, 'Orders'),
    ('/admin/customers', Icons.people_outline, 'Customers'),
    ('/admin/coupons', Icons.local_offer_outlined, 'Coupons'),
    ('/admin/bulk-discounts', Icons.stacked_bar_chart_outlined, 'Bulk Discounts'),
    ('/admin/reports', Icons.insights_outlined, 'Reports'),
    ('/admin/disputes', Icons.gavel_outlined, 'Disputes'),
    ('/admin/notifications', Icons.notifications_none, 'Notifications'),
    ('/admin/search', Icons.manage_search_outlined, 'Search Management'),
    ('/admin/settings', Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0EB),
      body: Row(
        children: [
          Container(
            width: 248,
            color: MazonnColors.noir,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text('MAZONN', style: TextStyle(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.w700)),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text('Super Admin', style: TextStyle(color: Color(0xFFD4C4B0), fontSize: 12)),
                  ),
                  Expanded(
                    child: ListView(
                      children: destinations.map((d) {
                        final selected = loc == d.$1 || (d.$1 != '/admin' && loc.startsWith(d.$1));
                        return ListTile(
                          dense: true,
                          leading: Icon(d.$2, color: selected ? MazonnColors.goldSoft : const Color(0xFFB7B0A7), size: 20),
                          title: Text(
                            d.$3,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFFB7B0A7),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          selected: selected,
                          onTap: () => context.go(d.$1),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFB7B0A7), size: 20),
                    title: Text(auth.user?.fullName ?? 'Sign out', style: const TextStyle(color: Color(0xFFB7B0A7))),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/admin/login');
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
