import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/order_repository.dart';
import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../models/catalog_extras.dart';
import '../../models/order.dart';

class OrderController extends ChangeNotifier {
  OrderController(this._repository);

  final OrderRepository _repository;
  List<Order> _orders = [];
  bool _loading = false;
  Order? lastPlaced;

  List<Order> get orders => _orders;
  bool get loading => _loading;

  List<Order> byStatus(OrderStatus? status) {
    if (status == null) return _orders;
    return _orders.where((o) => o.status == status).toList();
  }

  Order? byId(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _orders = await _repository.fetchUserOrders();
    _loading = false;
    notifyListeners();
  }

  Future<Order> place({
    required List<CartItem> items,
    required Address address,
    required DeliveryOption delivery,
    required PaymentOption payment,
    required double subtotal,
    required double discount,
    required double deliveryFee,
    required double total,
    String customerId = '',
  }) async {
    final order = Order(
      id: 'MS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      placedAt: DateTime.now(),
      items: items
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
            ),
          )
          .toList(),
      status: OrderStatus.processing,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      addressLabel: address.label,
      addressLine: address.summary,
      deliveryMethod: delivery.label,
      paymentMethod: payment.label,
      vendorId: items.isNotEmpty ? items.first.product.vendorId : AppConstants.appName,
      customerId: customerId,
    );
    lastPlaced = await _repository.placeOrder(order);
    _orders.insert(0, lastPlaced!);
    notifyListeners();
    return lastPlaced!;
  }
}
