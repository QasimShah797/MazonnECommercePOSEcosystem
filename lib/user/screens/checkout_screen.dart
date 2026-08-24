import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/catalog_extras.dart';
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
    final deliveryFee = cart.deliveryFee(express);
    final total = cart.subtotal + deliveryFee;

    return Scaffold(
      appBar: const MazonnAppBar(title: 'Checkout'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _sectionTitle(context, 'Address'),
          if (address == null)
            const Text('Add a delivery address to continue.')
          else
            _card(
              child: RadioGroup<String>(
                groupValue: address.id,
                onChanged: (id) {
                  if (id != null) addresses.select(id);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...addresses.addresses.map(
                      (a) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: a.id,
                        title: Text('${a.label} · ${a.fullName}'),
                        subtitle: Text(a.summary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/shop/profile/addresses'),
                      child: const Text('Add or edit addresses'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Delivery'),
          _card(
            child: RadioGroup<DeliveryOption>(
              groupValue: _delivery,
              onChanged: (v) => setState(() => _delivery = v ?? _delivery),
              child: Column(
                children: DeliveryOption.values
                    .map(
                      (option) => RadioListTile<DeliveryOption>(
                        contentPadding: EdgeInsets.zero,
                        value: option,
                        title: Text(option.label),
                        subtitle: Text(
                          '${option.subtitle} · ${MazonnFormatters.money(cart.deliveryFee(option == DeliveryOption.express))}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Payment'),
          _card(
            child: RadioGroup<PaymentOption>(
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v ?? _payment),
              child: Column(
                children: PaymentOption.values
                    .map(
                      (option) => RadioListTile<PaymentOption>(
                        contentPadding: EdgeInsets.zero,
                        value: option,
                        title: Text(option.label),
                        subtitle: Text(option.subtitle),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Order summary'),
          _card(
            child: Column(
              children: [
                ...cart.items.map(
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
                _kv(context, 'Subtotal', MazonnFormatters.money(cart.subtotal)),
                _kv(context, 'Discount', MazonnFormatters.money(cart.discount)),
                _kv(context, 'Delivery', MazonnFormatters.money(deliveryFee)),
                const SizedBox(height: 6),
                _kv(context, 'Total', MazonnFormatters.money(total), strong: true),
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
                      final order = await context.read<OrderController>().place(
                            items: cart.items,
                            address: address,
                            delivery: _delivery,
                            payment: _payment,
                            subtotal: cart.subtotal,
                            discount: cart.discount,
                            deliveryFee: deliveryFee,
                            total: total,
                            customerId: context.read<AuthController>().user?.id ?? '',
                          );
                      await cart.clear();
                      if (!context.mounted) return;
                      context.go('/shop/order-success', extra: order.id);
                    } catch (_) {
                      if (!context.mounted) return;
                      setState(() => _placing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not place this order. Please try again.')),
                      );
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
              Text('Order placed', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Thank you. ${orderId ?? 'Your order'} is being prepared by the atelier.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
              ),
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
