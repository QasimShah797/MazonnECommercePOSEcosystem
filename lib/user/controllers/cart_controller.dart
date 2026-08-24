import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
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

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  double get discount {
    return _items.fold(0, (sum, item) {
      final original = item.product.originalPrice;
      if (original == null || original <= item.product.price) return sum;
      return sum + ((original - item.product.price) * item.quantity);
    });
  }

  double deliveryFee(bool express) {
    if (subtotal >= AppConstants.freeShippingThreshold && !express) return 0;
    return express ? AppConstants.expressDeliveryFee : AppConstants.standardDeliveryFee;
  }

  double total({required bool express}) => subtotal + deliveryFee(express);

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
