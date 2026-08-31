import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_image.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../user/screens/orders_screen.dart';
import '../controllers/vendor_studio_controller.dart';
import '../widgets/vendor_access_gate.dart';

class VendorProductsScreen extends StatelessWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    return VendorAccessGate(
      feature: 'product publishing',
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () => context.push('/studio/products/form'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: studio.products.isEmpty
          ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'Publish your first piece.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: studio.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = studio.products[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: MazonnColors.white, borderRadius: MazonnRadius.card),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 72,
                        child: MazonnImage.product(p),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                            Text('${MazonnFormatters.money(p.price)} · Stock ${p.stock} · ${p.sales} sold', style: Theme.of(context).textTheme.bodySmall),
                            StatusChip(
                              label: p.moderation.label,
                              color: p.moderation == ProductModeration.approved
                                  ? MazonnColors.success
                                  : p.moderation == ProductModeration.rejected
                                      ? MazonnColors.error
                                      : MazonnColors.warning,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') context.push('/studio/products/form', extra: p);
                          if (value == 'toggle') await studio.toggleActive(p);
                          if (value == 'delete') await studio.deleteProduct(p.id);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'toggle', child: Text(p.isActive ? 'Disable' : 'Enable')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    return VendorAccessGate(
      feature: 'order management',
      child: DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Orders'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MazonnColors.noir,
            indicatorColor: MazonnColors.gold,
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'Processing'),
              Tab(text: 'Shipped'),
              Tab(text: 'Delivered'),
              Tab(text: 'Rejected'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(studio.byStatus(OrderStatus.pending)),
            _list(studio.byStatus(OrderStatus.processing)),
            _list(studio.byStatus(OrderStatus.shipped)),
            _list(studio.byStatus(OrderStatus.delivered)),
            _list(studio.byStatus(OrderStatus.rejected)),
            _list(studio.byStatus(OrderStatus.cancelled)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _list(List<Order> orders) {
    if (orders.isEmpty) {
      return const EmptyState(icon: Icons.local_shipping_outlined, title: 'No orders', message: 'Incoming orders will land here.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: orders.map((o) => Padding(padding: const EdgeInsets.only(bottom: 10), child: OrderCard(order: o, showVendorActions: true))).toList(),
    );
  }
}

class VendorOrderDetailsScreen extends StatelessWidget {
  const VendorOrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    final order = studio.orderById(orderId);
    if (order == null) {
      return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Not found', message: ''));
    }
    return VendorAccessGate(
      feature: 'order management',
      child: Scaffold(
      appBar: MazonnAppBar(title: order.id),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('NEW ORDER #${order.id}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('${order.customerName.isEmpty ? 'Customer' : order.customerName} · ${order.itemCount} items'),
          Text(MazonnFormatters.dateTime(order.placedAt), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          StatusChip(
            label: order.status.label,
            color: switch (order.status) {
              OrderStatus.pending => MazonnColors.warning,
              OrderStatus.processing => MazonnColors.warning,
              OrderStatus.shipped => MazonnColors.info,
              OrderStatus.delivered => MazonnColors.success,
              OrderStatus.cancelled => MazonnColors.error,
              OrderStatus.rejected => MazonnColors.error,
            },
          ),
          const SizedBox(height: 12),
          Text(order.addressLine),
          Text(order.paymentMethod),
          const Divider(height: 28),
          ...order.items.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.name),
                subtitle: Text('×${e.quantity}'),
                trailing: Text(MazonnFormatters.money(e.lineTotal)),
              )),
          const Divider(height: 28),
          Text('Total ${MazonnFormatters.money(order.total)}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (order.status == OrderStatus.pending) ...[
            MazonnButton(label: 'ACCEPT', onPressed: () => studio.acceptOrder(order.id)),
            const SizedBox(height: 10),
            MazonnButton(
              label: 'REJECT',
              tone: MazonnButtonTone.outline,
              onPressed: () => studio.rejectOrder(order.id),
            ),
          ],
          if (order.status == OrderStatus.processing)
            MazonnButton(
              label: 'Mark shipped',
              onPressed: () => studio.updateOrderStatus(order.id, OrderStatus.shipped),
            ),
          if (order.status == OrderStatus.shipped) ...[
            const SizedBox(height: 8),
            MazonnButton(
              label: 'Mark delivered',
              onPressed: () => studio.updateOrderStatus(order.id, OrderStatus.delivered),
            ),
          ],
          const SizedBox(height: 8),
          if (OrderTransitions.canTransition(order.status, OrderStatus.cancelled))
            MazonnButton(
              label: 'Cancel order',
              tone: MazonnButtonTone.outline,
              onPressed: () => studio.updateOrderStatus(order.id, OrderStatus.cancelled),
            ),
        ],
      ),
    ),
    );
  }
}
