import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';
import '../../models/bulk_pricing.dart';
import '../../models/catalog_extras.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';

class AdminController extends ChangeNotifier {
  AdminController(this._repository);

  final AdminRepository _repository;
  List<Vendor> vendors = [];
  List<Product> products = [];
  List<Order> orders = [];
  List<AppUser> customers = [];
  List<AppNotification> notifications = [];
  bool loading = false;
  String? error;
  String query = '';

  int get totalVendors => vendors.length;
  int get activeVendors => vendors.where((v) => v.approvalStatus == 'approved').length;
  int get pendingVendors => vendors.where((v) => v.approvalStatus == 'pending').length;
  int get totalCustomers => customers.where((c) => c.role != 'vendor').length;
  int get totalProducts => products.length;
  int get pendingProducts => products.where((p) => p.moderation == ProductModeration.pending).length;
  int get todayOrders => orders.where((o) => _isToday(o.placedAt)).length;
  double get todayRevenue => orders
      .where((o) => _isToday(o.placedAt) && o.status != OrderStatus.cancelled && o.status != OrderStatus.rejected)
      .fold(0, (sum, o) => sum + o.total);
  int get pendingOrders => orders.where((o) => o.status == OrderStatus.pending).length;
  int get cancelledOrders => orders.where((o) => o.status == OrderStatus.cancelled).length;

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month && value.day == now.day;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snap = await _repository.load();
      vendors = snap.vendors;
      products = snap.products;
      orders = snap.orders;
      customers = snap.customers;
      notifications = snap.notifications;
    } catch (_) {
      error = 'Unable to load the admin workspace.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  List<Vendor> get filteredVendors {
    if (query.isEmpty) return vendors;
    return vendors
        .where((v) =>
            v.businessName.toLowerCase().contains(query) ||
            v.ownerName.toLowerCase().contains(query) ||
            v.email.toLowerCase().contains(query))
        .toList();
  }

  List<Product> get filteredProducts {
    if (query.isEmpty) return products;
    return products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.vendorName.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query))
        .toList();
  }

  List<Order> get filteredOrders {
    if (query.isEmpty) return orders;
    return orders
        .where((o) =>
            o.id.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query) ||
            o.vendorName.toLowerCase().contains(query))
        .toList();
  }

  List<AppUser> get filteredCustomers {
    if (query.isEmpty) return customers;
    return customers
        .where((c) =>
            c.fullName.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query))
        .toList();
  }

  Future<void> setVendorStatus(String id, String status, String actorId, {String reason = '', String actorName = ''}) async {
    await _repository.setVendorStatus(id, status, reason: reason, actorId: actorId, actorName: actorName);
    await _repository.writeAudit(
      action: 'vendor_$status',
      actorId: actorId,
      targetId: id,
      detail: reason.isEmpty ? null : reason,
    );
    await load();
  }

  Future<void> approveProduct(String id, String actorId) async {
    await _repository.setProductModeration(id, ProductModeration.approved);
    await _repository.writeAudit(action: 'product_approved', actorId: actorId, targetId: id);
    await load();
  }

  Future<void> rejectProduct(String id, String reason, String actorId) async {
    await _repository.setProductModeration(id, ProductModeration.rejected, reason: reason);
    await _repository.writeAudit(action: 'product_rejected', actorId: actorId, targetId: id, detail: reason);
    await load();
  }

  Future<void> setUserSuspended(String id, bool suspended, String actorId) async {
    await _repository.setUserSuspended(id, suspended);
    await _repository.writeAudit(
      action: suspended ? 'customer_suspended' : 'customer_reactivated',
      actorId: actorId,
      targetId: id,
    );
    await load();
  }

  Future<void> saveBulkRules(Product product, List<BulkPricingRule> rules, String actorId) async {
    if (PricingEngine.rangesOverlap(rules)) {
      throw StateError('Bulk pricing tiers cannot overlap.');
    }
    await _repository.saveProduct(product.copyWith(bulkPricing: rules));
    await _repository.writeAudit(action: 'bulk_pricing_updated', actorId: actorId, targetId: product.id);
    await load();
  }
}
