import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/order_ids.dart';
import '../../data/repositories/order_repository.dart';
import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../models/catalog_extras.dart';
import '../../models/order.dart';
import '../../models/vendor_cart_group.dart';

class OrderController extends ChangeNotifier {
  OrderController(this._repository);

  final OrderRepository _repository;
  StreamSubscription<List<Order>>? _watch;
  List<Order> _orders = [];
  bool _loading = false;
  String? _error;
  Order? lastPlaced;
  List<Order> lastPlacedOrders = [];

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  List<Order> byStatus(OrderStatus? status) {
    if (status == null) return _orders;
    return _orders.where((o) => o.status == status).toList();
  }

  Order? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    for (final order in lastPlacedOrders) {
      if (order.id == id) return order;
    }
    return lastPlaced?.id == id ? lastPlaced : null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.fetchUserOrders();
    } catch (_) {
      _error = 'Unable to load orders right now.';
    } finally {
      _loading = false;
      notifyListeners();
    }
    await _watch?.cancel();
    _watch = _repository.watchUserOrders().listen((list) {
      _orders = list;
      notifyListeners();
    });
  }

  Future<List<Order>> place({
    required List<CartItem> items,
    required Address address,
    required DeliveryOption delivery,
    required PaymentOption payment,
    required double subtotal,
    required double discount,
    required double deliveryFee,
    required double total,
    String customerId = '',
    String customerName = '',
    List<VendorCartGroup>? groups,
  }) async {
    final vendorGroups = groups ?? items.grouped();
    if (vendorGroups.isEmpty) {
      throw StateError('Your bag is empty.');
    }
    final created = <Order>[];
    for (final group in vendorGroups) {
      final quoteSubtotal = group.merchandiseSubtotal;
      final quoteDiscount = group.bulkDiscount + group.couponDiscount;
      final order = Order(
        id: OrderIds.next(),
        placedAt: DateTime.now(),
        items: group.items
            .map(
              (e) => OrderItem(
                productId: e.product.id,
                name: e.product.name,
                brand: e.product.brand,
                price: e.product.price,
                quantity: e.quantity,
                visualSeed: e.product.visualSeed,
                color: e.selectedColor,
                size: e.selectedSize,
                imageUrl: e.product.primaryImage,
                bulkDiscount: e.bulkDiscount,
              ),
            )
            .toList(),
        status: OrderStatus.pending,
        subtotal: quoteSubtotal,
        discount: quoteDiscount,
        deliveryFee: group.deliveryFee,
        total: group.vendorTotal,
        addressLabel: address.label,
        addressLine: address.summary,
        deliveryMethod: delivery.label,
        paymentMethod: payment.label,
        vendorId: group.vendorId,
        vendorName: group.vendorName,
        customerName: customerName,
        customerId: customerId,
        couponDiscount: group.couponDiscount,
      );
      created.add(await _repository.placeOrder(order));
    }
    lastPlacedOrders = created;
    lastPlaced = created.first;
    _orders.insertAll(0, created);
    notifyListeners();
    return created;
  }

  Future<void> cancel(String id) async {
    final updated = await _repository.updateStatus(id, OrderStatus.cancelled);
    final index = _orders.indexWhere((o) => o.id == id);
    if (index >= 0) _orders[index] = updated;
    notifyListeners();
  }
}
