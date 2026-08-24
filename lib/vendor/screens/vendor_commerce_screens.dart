import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../shared/widgets/mazonn_visual.dart';
import '../../../user/screens/orders_screen.dart';
import '../controllers/vendor_studio_controller.dart';

class VendorProductsScreen extends StatelessWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    return Scaffold(
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
                        child: MazonnVisual(seed: p.visualSeed, categoryId: p.categoryId, monogram: p.brand.substring(0, 1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                            Text('${MazonnFormatters.money(p.price)} · Stock ${p.stock} · ${p.sales} sold', style: Theme.of(context).textTheme.bodySmall),
                            StatusChip(
                              label: p.isActive ? 'Active' : 'Disabled',
                              color: p.isActive ? MazonnColors.success : MazonnColors.stone,
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
    );
  }
}

class VendorProductFormScreen extends StatefulWidget {
  const VendorProductFormScreen({super.key, this.existing});
  final Product? existing;

  @override
  State<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _brand;
  late final TextEditingController _variants;
  String _category = 'fashion';
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name);
    _desc = TextEditingController(text: p?.description);
    _price = TextEditingController(text: p?.price.toString());
    _discount = TextEditingController(text: p?.originalPrice?.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '10');
    _sku = TextEditingController(text: p?.sku ?? 'AN-NEW');
    _brand = TextEditingController(text: p?.brand ?? 'Atelier Noir');
    _variants = TextEditingController(text: p == null ? 'Stone, Noir' : p.colors.join(', '));
    _category = p?.categoryId ?? 'fashion';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _sku.dispose();
    _brand.dispose();
    _variants.dispose();
    super.dispose();
  }

  Product _build({required bool active}) {
    final vendor = context.read<AuthController>().vendor;
    final price = double.tryParse(_price.text) ?? 0;
    final original = double.tryParse(_discount.text);
    return Product(
      id: widget.existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text,
      brand: _brand.text,
      description: _desc.text,
      categoryId: _category,
      vendorId: vendor?.id ?? MockCatalog.vendorId,
      vendorName: vendor?.businessName ?? 'Studio',
      price: price,
      originalPrice: original,
      rating: widget.existing?.rating ?? 5,
      reviewCount: widget.existing?.reviewCount ?? 0,
      stock: int.tryParse(_stock.text) ?? 0,
      sku: _sku.text,
      visualSeed: widget.existing?.visualSeed ?? DateTime.now().millisecond,
      colors: _variants.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      isActive: active,
      sales: widget.existing?.sales ?? 0,
    );
  }

  Future<void> _save({required bool publish}) async {
    if (!_form.currentState!.validate()) return;
    await context.read<VendorStudioController>().saveProduct(_build(active: publish));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MazonnAppBar(title: widget.existing == null ? 'Add product' : 'Edit product'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: MazonnVisual(seed: widget.existing?.visualSeed ?? 7, categoryId: _category, monogram: 'IMG'),
            ),
            const SizedBox(height: 8),
            Text('Product images (placeholders — replace later with studio photos)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            MazonnTextField(label: 'Product name', controller: _name, validator: (v) => MazonnValidators.requiredField(v, label: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: MockCatalog.categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Description', controller: _desc, maxLines: 4),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Price', controller: _price, keyboardType: TextInputType.number, validator: MazonnValidators.price),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Original price / discount from', controller: _discount, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Stock quantity', controller: _stock, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            MazonnTextField(label: 'SKU', controller: _sku),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Brand', controller: _brand),
            const SizedBox(height: 12),
            MazonnTextField(label: 'Variants (comma separated)', controller: _variants),
            const SizedBox(height: 20),
            MazonnButton(label: 'Save draft', tone: MazonnButtonTone.outline, onPressed: () => _save(publish: false)),
            const SizedBox(height: 10),
            MazonnButton(label: 'Publish product', onPressed: () => _save(publish: true)),
          ],
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
    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(studio.byStatus(OrderStatus.processing)),
            _list(studio.byStatus(OrderStatus.processing)),
            _list(studio.byStatus(OrderStatus.shipped)),
            _list(studio.byStatus(OrderStatus.delivered)),
            _list(studio.byStatus(OrderStatus.cancelled)),
          ],
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
    return Scaffold(
      appBar: MazonnAppBar(title: order.id),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(order.status.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Customer delivery'),
          Text(order.addressLine),
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
          if (order.status == OrderStatus.processing)
            MazonnButton(
              label: 'Accept / mark shipped',
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
          if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
            MazonnButton(
              label: 'Cancel order',
              tone: MazonnButtonTone.outline,
              onPressed: () => studio.updateOrderStatus(order.id, OrderStatus.cancelled),
            ),
        ],
      ),
    );
  }
}
