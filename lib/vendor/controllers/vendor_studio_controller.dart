import 'package:flutter/material.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/session_service.dart';

class VendorStudioController extends ChangeNotifier {
  VendorStudioController({
    required OrderRepository orders,
    required ProductRepository products,
    required SessionService session,
  })  : _orders = orders,
        _productsRepo = products,
        _session = session;

  final OrderRepository _orders;
  final ProductRepository _productsRepo;
  final SessionService _session;

  List<Product> _products = [];
  List<Order> _orderList = [];
  bool _loading = false;

  List<Product> get products => _products;
  List<Order> get orderList => _orderList;
  bool get loading => _loading;

  double get todayRevenue => _orderList
      .where((o) => o.status != OrderStatus.cancelled)
      .fold(0, (sum, o) => sum + o.total);

  int get pendingCount =>
      _orderList.where((o) => o.status == OrderStatus.processing).length;

  int get lowStockCount => _products.where((p) => p.isLowStock || !p.inStock).length;

  List<Product> get lowStock =>
      _products.where((p) => p.isLowStock || !p.inStock).toList();

  List<Product> get topProducts {
    final copy = List<Product>.from(_products)..sort((a, b) => b.sales.compareTo(a.sales));
    return copy.take(5).toList();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final vendorId = _session.vendor?.id;
    if (vendorId != null) {
      _products = await _productsRepo.fetchVendorProducts(vendorId);
    } else {
      _products = _session.readVendorProducts(const []);
    }
    _orderList = await _orders.fetchVendorOrders();
    _loading = false;
    notifyListeners();
  }

  Product? productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Order? orderById(String id) {
    try {
      return _orderList.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Order> byStatus(OrderStatus? status) {
    if (status == null) return _orderList;
    return _orderList.where((o) => o.status == status).toList();
  }

  Future<void> saveProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
    await _productsRepo.upsertProduct(product);
    await _session.writeVendorProducts(_products);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await _productsRepo.deleteProduct(id);
    await _session.writeVendorProducts(_products);
    notifyListeners();
  }

  Future<void> toggleActive(Product product) async {
    await saveProduct(product.copyWith(isActive: !product.isActive));
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final updated = await _orders.updateStatus(id, status);
    final index = _orderList.indexWhere((o) => o.id == id);
    if (index >= 0) _orderList[index] = updated;
    notifyListeners();
  }
}
