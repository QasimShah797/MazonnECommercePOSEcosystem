import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_image.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/order_controller.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderController>();
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Orders'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MazonnColors.noir,
            unselectedLabelColor: MazonnColors.stone,
            indicatorColor: MazonnColors.gold,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Processing'),
              Tab(text: 'Shipped'),
              Tab(text: 'Delivered'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(orders: orders.orders),
            _OrderList(orders: [...orders.byStatus(OrderStatus.pending), ...orders.byStatus(OrderStatus.rejected)]),
            _OrderList(orders: orders.byStatus(OrderStatus.processing)),
            _OrderList(orders: orders.byStatus(OrderStatus.shipped)),
            _OrderList(orders: orders.byStatus(OrderStatus.delivered)),
            _OrderList(orders: orders.byStatus(OrderStatus.cancelled)),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders here',
        message: 'When you place an order, it will appear in this list.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => OrderCard(order: orders[i]),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.showVendorActions = false});

  final Order order;
  final bool showVendorActions;

  Color get _color => switch (order.status) {
        OrderStatus.pending => MazonnColors.stone,
        OrderStatus.processing => MazonnColors.warning,
        OrderStatus.shipped => MazonnColors.info,
        OrderStatus.delivered => MazonnColors.success,
        OrderStatus.cancelled => MazonnColors.error,
        OrderStatus.rejected => MazonnColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MazonnColors.white,
        borderRadius: MazonnRadius.card,
        boxShadow: MazonnShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.id, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              StatusChip(label: order.status.label, color: _color),
            ],
          ),
          const SizedBox(height: 4),
          Text(MazonnFormatters.dateTime(order.placedAt), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(
                width: 52,
                child: MazonnImage(
                  url: order.items[i].imageUrl,
                  seed: order.items[i].visualSeed,
                  monogram: '',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}  ·  ${MazonnFormatters.money(order.total)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MazonnButton(
                  label: 'Details',
                  tone: MazonnButtonTone.outline,
                  onPressed: () => context.push(
                    showVendorActions ? '/studio/orders/${order.id}' : '/shop/orders/${order.id}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MazonnButton(
                  label: showVendorActions ? 'Manage' : 'Track',
                  onPressed: () => context.push(
                    showVendorActions ? '/studio/orders/${order.id}' : '/shop/orders/${order.id}/track',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderController>().byId(orderId);
    if (order == null) {
      return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Order not found', message: ''));
    }
    return Scaffold(
      appBar: MazonnAppBar(title: order.id),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 48,
                height: 48,
                child: MazonnImage(
                  url: item.imageUrl,
                  seed: item.visualSeed,
                  monogram: '',
                ),
              ),
              title: Text(item.name),
              subtitle: Text('${item.brand} · ×${item.quantity}'),
              trailing: Text(MazonnFormatters.money(item.lineTotal)),
            ),
          ),
          const Divider(height: 28),
          Text('Deliver to ${order.addressLabel}', style: Theme.of(context).textTheme.titleSmall),
          Text(order.addressLine),
          const SizedBox(height: 12),
          Text('${order.vendorName.isEmpty ? '' : '${order.vendorName} · '}${order.deliveryMethod} · ${order.paymentMethod}'),
          const SizedBox(height: 8),
          Text('Subtotal ${MazonnFormatters.money(order.subtotal)}'),
          Text('Discount ${MazonnFormatters.money(order.discount)}'),
          Text('Delivery ${MazonnFormatters.money(order.deliveryFee)}'),
          const SizedBox(height: 16),
          Text('Total ${MazonnFormatters.money(order.total)}', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderController>().byId(orderId);
    if (order == null) {
      return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Order not found', message: ''));
    }
    final steps = ['Placed', 'Processing', 'Shipped', 'Delivered'];
    final current = switch (order.status) {
      OrderStatus.pending => 0,
      OrderStatus.processing => 1,
      OrderStatus.shipped => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => 0,
      OrderStatus.rejected => 0,
    };
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Track order'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.id, style: Theme.of(context).textTheme.headlineSmall),
            if (order.trackingCode != null)
              Text('Tracking ${order.trackingCode}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 28),
            if (order.status == OrderStatus.cancelled)
              const Text('This order was cancelled.')
            else if (order.status == OrderStatus.rejected)
              const Text('This order was rejected by the vendor.')
            else
              ...List.generate(steps.length, (i) {
                final done = i <= current;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: done ? MazonnColors.noir : MazonnColors.linen,
                          child: Icon(Icons.check, size: 14, color: done ? Colors.white : MazonnColors.stone),
                        ),
                        if (i < steps.length - 1)
                          Container(
                            width: 2,
                            height: 36,
                            color: i < current ? MazonnColors.noir : MazonnColors.linen,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        steps[i],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: done ? MazonnColors.noir : MazonnColors.stoneLight,
                            ),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
