import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../models/vendor_cart_group.dart';
import '../../services/session_service.dart';

class CartController extends ChangeNotifier {
  CartController(this._session) {
    _items = _session.readCart();
  }

  final SessionService _session;
  List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  double get merchandiseSubtotal => _items.fold(0, (sum, item) => sum + item.quote.subtotal);
  double get bulkDiscount => _items.fold(0, (sum, item) => sum + item.bulkDiscount);
  double get catalogDiscount => _items.fold(0.0, (sum, item) {
        final original = item.product.originalPrice;
        if (original == null || original <= item.product.price) return sum;
        return sum + ((original - item.product.price) * item.quantity);
      });
  double get discount => bulkDiscount + catalogDiscount;
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  List<VendorCartGroup> groups({required bool express}) {
    return _items.grouped(
      deliveryFeeFor: (group) {
        if (group.merchandiseSubtotal - group.bulkDiscount >= AppConstants.freeShippingThreshold && !express) {
          return 0;
        }
        return express ? AppConstants.expressDeliveryFee : AppConstants.standardDeliveryFee;
      },
    );
  }

  double deliveryFee(bool express) =>
      groups(express: express).fold(0.0, (sum, group) => sum + group.deliveryFee);

  double total({required bool express}) =>
      groups(express: express).fold(0.0, (sum, group) => sum + group.vendorTotal);

  Future<void> add(
    Product product, {
    int quantity = 1,
    String? color,
    String? size,
  }) async {
    final key = '${product.id}|${color ?? ''}|${size ?? ''}';
    final index = _items.indexWhere((e) => e.variantKey == key);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedColor: color,
          selectedSize: size,
        ),
      );
    }
    await _persist();
  }

  Future<void> setQuantity(String variantKey, int quantity) async {
    if (quantity <= 0) {
      await remove(variantKey);
      return;
    }
    final index = _items.indexWhere((e) => e.variantKey == variantKey);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      await _persist();
    }
  }

  Future<void> remove(String variantKey) async {
    _items.removeWhere((e) => e.variantKey == variantKey);
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    await _persist();
  }

  Future<void> _persist() async {
    await _session.writeCart(_items);
    notifyListeners();
  }
}
