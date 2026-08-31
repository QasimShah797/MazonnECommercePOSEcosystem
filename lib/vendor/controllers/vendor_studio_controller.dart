import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/bulk_pricing.dart';
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
  StreamSubscription<List<Order>>? _watch;

  List<Product> _products = [];
  List<Order> _orderList = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  List<Order> get orderList => _orderList;
  bool get loading => _loading;
  String? get error => _error;

  double get todayRevenue {
    final now = DateTime.now();
    return _orderList
        .where((o) =>
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.rejected &&
            o.placedAt.year == now.year &&
            o.placedAt.month == now.month &&
            o.placedAt.day == now.day)
        .fold(0, (sum, o) => sum + o.total);
  }

  int get pendingCount => _orderList.where((o) => o.status == OrderStatus.pending).length;

  int get lowStockCount => _products.where((p) => p.isLowStock || !p.inStock).length;

  List<Product> get lowStock =>
      _products.where((p) => p.isLowStock || !p.inStock).toList();

  List<Product> get topProducts {
    final copy = List<Product>.from(_products)..sort((a, b) => b.sales.compareTo(a.sales));
    return copy.take(5).toList();
  }

  List<Product> get pendingModeration =>
      _products.where((p) => p.moderation == ProductModeration.pending).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final vendorId = _session.vendor?.id;
      if (vendorId != null) {
        _products = await _productsRepo.fetchVendorProducts(vendorId);
      } else {
        _products = _session.readVendorProducts(const []);
      }
      if (_session.vendor?.canSell == true) {
        _orderList = await _orders.fetchVendorOrders();
      } else {
        _orderList = [];
      }
    } catch (_) {
      _error = 'Unable to load studio data right now.';
    } finally {
      _loading = false;
      notifyListeners();
    }
    await _watch?.cancel();
    _watch = _orders.watchVendorOrders().listen((list) {
      _orderList = list;
      notifyListeners();
    });
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
    if (PricingEngine.rangesOverlap(product.bulkPricing)) {
      throw StateError('Bulk pricing tiers cannot overlap.');
    }
    final vendor = _session.vendor;
    if (vendor != null && !vendor.canSell) {
      throw StateError(
        vendor.billingStatus == 'read_only'
            ? 'Your store is read-only until subscription billing is restored.'
            : 'Your vendor account is under review. You will be able to sell on the platform after Super Admin approval.',
      );
    }
    final publishing = product.moderation == ProductModeration.pending ||
        product.moderation == ProductModeration.approved;
    if (publishing && !product.hasValidPrimaryImage) {
      throw StateError('Add a valid primary image before publishing this product.');
    }
    final cap = vendor?.listingCap ?? 20;
    final liveCount = _products.where((p) =>
        p.id != product.id &&
        (p.moderation == ProductModeration.pending || p.moderation == ProductModeration.approved)).length;
    if (publishing && liveCount >= cap) {
      throw StateError('Your ${vendor?.planId ?? 'basic'} plan allows $cap live listings. Upgrade your subscription to publish more.');
    }
    final stamped = product.copyWith(vendorApprovalStatus: vendor?.approvalStatus ?? product.vendorApprovalStatus);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = stamped;
    } else {
      _products.insert(0, stamped);
    }
    await _productsRepo.upsertProduct(stamped);
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
    if (_session.vendor?.canSell != true) {
      throw StateError('Your vendor account must be approved before you can manage orders.');
    }
    final updated = await _orders.updateStatus(id, status);
    final index = _orderList.indexWhere((o) => o.id == id);
    if (index >= 0) _orderList[index] = updated;
    notifyListeners();
  }

  Future<void> acceptOrder(String id) => updateOrderStatus(id, OrderStatus.processing);

  Future<void> rejectOrder(String id) => updateOrderStatus(id, OrderStatus.rejected);
}
