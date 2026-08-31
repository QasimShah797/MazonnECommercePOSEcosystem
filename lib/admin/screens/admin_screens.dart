import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/mock_catalog.dart';
import '../../models/bulk_pricing.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/vendor.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../shared/widgets/mazonn_button.dart';
import '../../shared/widgets/mazonn_image.dart';
import '../../shared/widgets/mazonn_ui.dart';
import '../../services/search_service.dart';
import '../../user/controllers/catalog_controller.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    if (admin.loading && admin.vendors.isEmpty) {
      return const LoadingState(label: 'Loading console');
    }
    if (admin.error != null && admin.vendors.isEmpty) {
      return ErrorState(message: admin.error!, onRetry: admin.load);
    }
    return _AdminScaffold(
      title: 'Dashboard',
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric('Total vendors', '${admin.totalVendors}'),
              _Metric('Active vendors', '${admin.activeVendors}'),
              _Metric('Pending vendors', '${admin.pendingVendors}'),
              _Metric('Customers', '${admin.totalCustomers}'),
              _Metric('Products', '${admin.totalProducts}'),
              _Metric('Pending products', '${admin.pendingProducts}'),
              _Metric("Today's orders", '${admin.todayOrders}'),
              _Metric("Today's revenue", MazonnFormatters.money(admin.todayRevenue)),
              _Metric('Pending orders', '${admin.pendingOrders}'),
              _Metric('Cancelled orders', '${admin.cancelledOrders}'),
            ],
          ),
          const SizedBox(height: 28),
          Text('Sales overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: MazonnRadius.card),
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: MazonnColors.goldDark,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    spots: _spots(admin.orders),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent orders', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _table(
            context,
            headers: const ['Order', 'Customer', 'Vendor', 'Status', 'Total'],
            rows: admin.orders.take(8).map((o) => [o.id, o.customerName, o.vendorName, o.status.label, MazonnFormatters.money(o.total)]).toList(),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _spots(List<Order> orders) {
    if (orders.isEmpty) {
      return const [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 1.6), FlSpot(3, 3), FlSpot(4, 2.4)];
    }
    final buckets = List<double>.filled(7, 0);
    final now = DateTime.now();
    for (final order in orders) {
      final day = now.difference(order.placedAt).inDays;
      if (day >= 0 && day < 7 && order.status != OrderStatus.cancelled && order.status != OrderStatus.rejected) {
        buckets[6 - day] += order.total;
      }
    }
    return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));
  }
}

class AdminVendorsScreen extends StatelessWidget {
  const AdminVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final actor = context.read<AuthController>().user?.id ?? 'admin';
    return _AdminScaffold(
      title: 'Vendors',
      search: true,
      child: admin.filteredVendors.isEmpty
          ? const EmptyState(icon: Icons.storefront_outlined, title: 'No vendors', message: 'Vendor applications will appear here.')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: admin.filteredVendors.map((v) => _VendorTile(vendor: v, actorId: actor)).toList(),
            ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({required this.vendor, required this.actorId});
  final Vendor vendor;
  final String actorId;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminController>();
    final products = admin.products.where((p) => p.vendorId == vendor.id).length;
    final orders = admin.orders.where((o) => o.vendorId == vendor.id).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: MazonnColors.cream, child: Text(vendor.logoLabel)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.businessName, style: Theme.of(context).textTheme.titleSmall),
                  Text('${vendor.ownerName} · ${vendor.email} · ${vendor.category}'),
                  Text('${vendor.address} · KYC ${vendor.approvalStatus} · $products products · $orders orders',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusChip(label: vendor.approvalStatus, color: _statusColor(vendor.approvalStatus)),
            const SizedBox(width: 8),
            if (vendor.approvalStatus == 'pending') ...[
              TextButton(onPressed: () => admin.setVendorStatus(vendor.id, 'approved', actorId), child: const Text('Approve')),
              TextButton(onPressed: () => admin.setVendorStatus(vendor.id, 'rejected', actorId), child: const Text('Reject')),
            ],
            if (vendor.approvalStatus == 'approved')
              TextButton(onPressed: () => admin.setVendorStatus(vendor.id, 'suspended', actorId), child: const Text('Suspend')),
            if (vendor.approvalStatus == 'suspended')
              TextButton(onPressed: () => admin.setVendorStatus(vendor.id, 'approved', actorId), child: const Text('Reactivate')),
          ],
        ),
      ),
    );
  }
}

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final actor = context.read<AuthController>().user?.id ?? 'admin';
    final pending = admin.filteredProducts.where((p) => p.moderation == ProductModeration.pending).toList();
    final rest = admin.filteredProducts.where((p) => p.moderation != ProductModeration.pending).toList();
    return _AdminScaffold(
      title: 'Product moderation',
      search: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Pending products', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text('No products awaiting approval.'),
            )
          else
            ...pending.map((p) => _ProductModerationTile(product: p, actorId: actor)),
          Text('Catalog', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (rest.isEmpty)
            const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'Approved products will appear here.')
          else
            ...rest.take(40).map((p) => _ProductModerationTile(product: p, actorId: actor, compact: true)),
        ],
      ),
    );
  }
}

class _ProductModerationTile extends StatelessWidget {
  const _ProductModerationTile({required this.product, required this.actorId, this.compact = false});
  final Product product;
  final String actorId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: MazonnImage.product(product, borderRadius: BorderRadius.circular(8)),
        ),
        title: Text(product.name),
        subtitle: Text(
          '${product.vendorName} · ${product.categoryId} · ${MazonnFormatters.money(product.price)} · Stock ${product.stock}\n${product.moderation.label}${product.rejectionReason.isEmpty ? '' : ' · ${product.rejectionReason}'}',
        ),
        isThreeLine: true,
        trailing: compact
            ? StatusChip(label: product.moderation.label, color: _statusColor(product.moderation.name))
            : Wrap(
                children: [
                  TextButton(
                    onPressed: () => admin.approveProduct(product.id, actorId),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final reason = await _askReason(context);
                      if (reason == null || reason.trim().isEmpty) return;
                      await admin.rejectProduct(product.id, reason.trim(), actorId);
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
      ),
    );
  }
}

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return _AdminScaffold(
      title: 'Orders',
      search: true,
      child: admin.filteredOrders.isEmpty
          ? const EmptyState(icon: Icons.local_shipping_outlined, title: 'No orders', message: 'Marketplace orders will appear here.')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: admin.filteredOrders.map((o) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${o.id} · ${MazonnFormatters.money(o.total)}'),
                    subtitle: Text(
                      '${o.customerName} · ${o.vendorName} · ${o.paymentMethod}\n${MazonnFormatters.dateTime(o.placedAt)} · ${o.itemCount} items · bulk ${MazonnFormatters.money(o.discount)}',
                    ),
                    isThreeLine: true,
                    trailing: StatusChip(label: o.status.label, color: _statusColor(o.status.name)),
                    onTap: () => context.push('/admin/orders/${o.id}'),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    Order? order;
    for (final item in admin.orders) {
      if (item.id == orderId) order = item;
    }
    if (order == null) {
      return const _AdminScaffold(title: 'Order', child: EmptyState(icon: Icons.help_outline, title: 'Not found', message: ''));
    }
    return _AdminScaffold(
      title: order.id,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text('${order.customerName} · ${order.vendorName}', style: Theme.of(context).textTheme.titleMedium),
          Text('${order.status.label} · ${order.paymentMethod} · ${MazonnFormatters.dateTime(order.placedAt)}'),
          const SizedBox(height: 16),
          ...order.items.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.name),
                subtitle: Text('×${e.quantity} · bulk ${MazonnFormatters.money(e.bulkDiscount)}'),
                trailing: Text(MazonnFormatters.money(e.lineTotal)),
              )),
          const Divider(),
          Text('Subtotal ${MazonnFormatters.money(order.subtotal)}'),
          Text('Discount ${MazonnFormatters.money(order.discount)}'),
          Text('Delivery ${MazonnFormatters.money(order.deliveryFee)}'),
          Text('Total ${MazonnFormatters.money(order.total)}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Deliver to ${order.addressLabel}\n${order.addressLine}'),
          const SizedBox(height: 16),
          Text('Admin monitoring only. Vendor/customer workflows remain the source of truth.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final actor = context.read<AuthController>().user?.id ?? 'admin';
    return _AdminScaffold(
      title: 'Customers',
      search: true,
      child: admin.filteredCustomers.isEmpty
          ? const EmptyState(icon: Icons.people_outline, title: 'No customers', message: 'Shop accounts will appear here.')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: admin.filteredCustomers.map((c) {
                final history = admin.orders.where((o) => o.customerId == c.id).length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(c.fullName),
                    subtitle: Text('${c.email} · ${c.city} · $history orders · ${c.suspended ? 'Suspended' : 'Active'}'),
                    trailing: TextButton(
                      onPressed: () => admin.setUserSuspended(c.id, !c.suspended, actor),
                      child: Text(c.suspended ? 'Reactivate' : 'Suspend'),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class AdminBulkScreen extends StatelessWidget {
  const AdminBulkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return _AdminScaffold(
      title: 'Bulk discounts',
      search: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Vendor-level rules are stored on each product. Platform campaigns can be layered as source=platform.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ...admin.filteredProducts.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(p.name),
                subtitle: Text('${p.vendorName} · ${p.bulkPricing.length} tiers'),
                children: [
                  ...p.bulkPricing.map((r) => ListTile(
                        title: Text('${r.minQty}${r.maxQty == null ? '+' : '–${r.maxQty}'}  ·  ${r.discountValue}${r.discountType == DiscountType.percent ? '%' : ''} off'),
                        subtitle: Text('${r.source} · ${r.active ? 'Active' : 'Inactive'}'),
                        trailing: Switch(
                          value: r.active,
                          onChanged: (v) {
                            final next = p.bulkPricing.map((e) => e.id == r.id ? e.copyWith(active: v) : e).toList();
                            admin.saveBulkRules(p, next, context.read<AuthController>().user?.id ?? 'admin');
                          },
                        ),
                      )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    return _AdminScaffold(
      title: 'Notifications',
      child: admin.notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'No notifications', message: 'Order and system events will appear here.')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: admin.notifications.map((n) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text('${n.type} · ${n.recipientId} · ${n.orderId ?? '—'}'),
                    trailing: Text(n.displayTime, style: Theme.of(context).textTheme.bodySmall),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _AdminScaffold(
      title: title,
      child: EmptyState(icon: Icons.tune, title: title, message: message),
    );
  }
}

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminScaffold(
      title: 'Categories',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: MockCatalog.categories
            .map((c) => Card(child: ListTile(title: Text(c.name), subtitle: Text(c.subtitle), leading: Icon(c.icon))))
            .toList(),
      ),
    );
  }
}

class AdminBrandsScreen extends StatelessWidget {
  const AdminBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AdminController>().products.map((p) => p.brand).toSet().toList()..sort();
    return _AdminScaffold(
      title: 'Brands',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: brands.map((b) => Card(child: ListTile(title: Text(b)))).toList(),
      ),
    );
  }
}

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final aliases = mazonnSearch.synonyms.aliases;
    return _AdminScaffold(
      title: 'Search Management',
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text('Synonyms and aliases', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'These mappings power predictive search and typo-tolerant ranking. Ranking rules stay in SearchService so Elasticsearch or Algolia can replace the local engine later.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (telly)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To (television)'))),
              const SizedBox(width: 12),
              MazonnButton(
                label: 'Add synonym',
                expanded: false,
                onPressed: () async {
                  await catalog.addSearchAlias(_from.text, _to.text);
                  _from.clear();
                  _to.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Popular searches: ${mazonnSearch.synonyms.popular.join(', ')}'),
          const SizedBox(height: 8),
          Text('Blocked terms: ${mazonnSearch.synonyms.blocked.isEmpty ? 'none yet' : mazonnSearch.synonyms.blocked.join(', ')}'),
          const SizedBox(height: 20),
          ...aliases.entries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.key),
                subtitle: Wrap(
                  spacing: 8,
                  children: entry.value
                      .map(
                        (alias) => InputChip(
                          label: Text(alias),
                          onDeleted: () => catalog.removeSearchAlias(entry.key, alias),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({required this.title, required this.child, this.search = false});
  final String title;
  final Widget child;
  final bool search;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: Colors.white,
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (search)
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search), isDense: true),
                    onChanged: context.read<AdminController>().setQuery,
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: MazonnRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

Widget _table(BuildContext context, {required List<String> headers, required List<List<String>> rows}) {
  return Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: MazonnRadius.card),
    child: DataTable(
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList())).toList(),
    ),
  );
}

Color _statusColor(String status) => switch (status) {
      'approved' || 'delivered' || 'active' => MazonnColors.success,
      'pending' || 'processing' => MazonnColors.warning,
      'rejected' || 'cancelled' || 'suspended' => MazonnColors.error,
      'shipped' => MazonnColors.info,
      _ => MazonnColors.stone,
    };

Future<String?> _askReason(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject product'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        MazonnButton(label: 'Reject', expanded: false, onPressed: () => Navigator.pop(context, controller.text)),
      ],
    ),
  );
}
