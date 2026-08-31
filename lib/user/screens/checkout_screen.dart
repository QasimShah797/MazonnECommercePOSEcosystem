import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/catalog_extras.dart';
import '../../../models/order.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/address_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryOption _delivery = DeliveryOption.standard;
  PaymentOption _payment = PaymentOption.cashOnDelivery;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final addresses = context.watch<AddressController>();
    final address = addresses.selected;
    final express = _delivery == DeliveryOption.express;
    final groups = cart.groups(express: express);
    final deliveryFee = cart.deliveryFee(express);
    final total = cart.total(express: express);

    return Scaffold(
      appBar: const MazonnAppBar(title: 'Checkout'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _sectionTitle(context, 'Address'),
          if (address == null)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add your Pakistan delivery location to place an order.'),
                  TextButton(
                    onPressed: () => context.push('/shop/profile/addresses/form'),
                    child: const Text('Add address'),
                  ),
                ],
              ),
            )
          else
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...addresses.addresses.map(
                    (a) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: a.id,
                      groupValue: address.id,
                      onChanged: (id) {
                        if (id != null) addresses.select(id);
                      },
                      title: Text('${a.label} · ${a.fullName}'),
                      subtitle: Text(a.summary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/shop/profile/addresses/form'),
                    child: const Text('Add another address'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Delivery'),
          _card(
            child: Column(
              children: DeliveryOption.values
                  .map(
                    (option) => RadioListTile<DeliveryOption>(
                      contentPadding: EdgeInsets.zero,
                      value: option,
                      groupValue: _delivery,
                      onChanged: (v) => setState(() => _delivery = v ?? _delivery),
                      title: Text(option.label),
                      subtitle: Text(
                        '${option.subtitle} · ${MazonnFormatters.money(cart.deliveryFee(option == DeliveryOption.express))}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Payment'),
          _card(
            child: Column(
              children: PaymentOption.values
                  .map(
                    (option) => RadioListTile<PaymentOption>(
                      contentPadding: EdgeInsets.zero,
                      value: option,
                      groupValue: _payment,
                      onChanged: (v) => setState(() => _payment = v ?? _payment),
                      title: Text(option.label),
                      subtitle: Text(option.subtitle),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Order summary'),
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.vendorName, style: Theme.of(context).textTheme.titleSmall),
                    ...group.items.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text('${e.product.name}  ×${e.quantity}')),
                            Text(MazonnFormatters.money(e.lineTotal)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    _kv(context, 'Subtotal', MazonnFormatters.money(group.merchandiseSubtotal)),
                    _kv(context, 'Bulk discount', MazonnFormatters.money(group.bulkDiscount)),
                    _kv(context, 'Delivery', MazonnFormatters.money(group.deliveryFee)),
                    _kv(context, 'Vendor total', MazonnFormatters.money(group.vendorTotal), strong: true),
                  ],
                ),
              ),
            ),
          ),
          _card(
            child: Column(
              children: [
                _kv(context, 'Grand total', MazonnFormatters.money(total), strong: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          MazonnButton(
            label: 'Place order',
            loading: _placing,
            onPressed: address == null
                ? null
                : () async {
                    setState(() => _placing = true);
                    try {
                      final orders = await context.read<OrderController>().place(
                            items: cart.items,
                            address: address,
                            delivery: _delivery,
                            payment: _payment,
                            subtotal: cart.merchandiseSubtotal,
                            discount: cart.bulkDiscount,
                            deliveryFee: deliveryFee,
                            total: total,
                            customerId: context.read<AuthController>().user?.id ?? '',
                            customerName: context.read<AuthController>().user?.fullName ?? '',
                            groups: groups,
                          );
                      await cart.clear();
                      if (!context.mounted) return;
                      context.go('/shop/order-success', extra: orders.first.id);
                    } catch (e) {
                      if (!context.mounted) return;
                      setState(() => _placing = false);
                      final message = e is StateError ? e.message : 'Could not place this order. Please try again.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MazonnColors.white,
        borderRadius: MazonnRadius.card,
        boxShadow: MazonnShadows.soft,
      ),
      child: child,
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool strong = false}) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [Text(k, style: style), const Spacer(), Text(v, style: style)]),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    final order = orderId == null ? controller.lastPlaced : controller.byId(orderId!);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: MazonnColors.cream, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 42, color: MazonnColors.success),
              ),
              const SizedBox(height: 24),
              Text('Order confirmed', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              if (order == null)
                Text(
                  'Thank you. ${orderId ?? 'Your order'} is awaiting vendor confirmation.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
                )
              else ...[
                Text('#${order.id}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${order.vendorName}\n${order.itemCount} items · ${order.paymentMethod}\n${order.addressLine}\nStatus: ${order.status.label}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
                ),
                const SizedBox(height: 16),
                Text('Subtotal ${MazonnFormatters.money(order.subtotal)}'),
                Text('Discount ${MazonnFormatters.money(order.discount)}'),
                Text('Delivery ${MazonnFormatters.money(order.deliveryFee)}'),
                Text('Total ${MazonnFormatters.money(order.total)}', style: Theme.of(context).textTheme.titleMedium),
              ],
              const Spacer(),
              MazonnButton(label: 'Track order', onPressed: () => context.go('/shop/orders')),
              const SizedBox(height: 12),
              MazonnButton(
                label: 'Continue shopping',
                tone: MazonnButtonTone.outline,
                onPressed: () => context.go('/shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
