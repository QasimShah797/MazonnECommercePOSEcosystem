import '../../models/catalog_extras.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import '../mock/mock_catalog.dart';

class AdminSnapshot {
  const AdminSnapshot({
    required this.vendors,
    required this.products,
    required this.orders,
    required this.customers,
    required this.notifications,
  });

  final List<Vendor> vendors;
  final List<Product> products;
  final List<Order> orders;
  final List<AppUser> customers;
  final List<AppNotification> notifications;
}

abstract class AdminRepository {
  Future<AdminSnapshot> load();
  Future<void> setVendorStatus(String vendorId, String status, {String reason = '', String actorId = '', String actorName = ''});
  Future<void> setProductModeration(String productId, ProductModeration status, {String reason = ''});
  Future<void> setUserSuspended(String userId, bool suspended);
  Future<void> saveProduct(Product product);
  Future<void> writeAudit({required String action, required String actorId, String? targetId, String? detail});
}

class MockAdminRepository implements AdminRepository {
  List<Vendor> _vendors = [MockCatalog.demoVendor];
  List<Product> _products = List.of(MockCatalog.products);
  final List<Order> _orders = List.of(MockCatalog.seedOrders);
  List<AppUser> _customers = [MockCatalog.demoUser, MockCatalog.demoAdmin];
  final List<AppNotification> _notifications = List.of(MockCatalog.notifications);

  @override
  Future<AdminSnapshot> load() async {
    return AdminSnapshot(
      vendors: _vendors,
      products: _products,
      orders: _orders,
      customers: _customers,
      notifications: _notifications,
    );
  }

  @override
  Future<void> setVendorStatus(String vendorId, String status, {String reason = '', String actorId = '', String actorName = ''}) async {
    _vendors = _vendors.map((v) {
      if (v.id != vendorId) return v;
      return v.copyWith(
        approvalStatus: status,
        rejectionReason: status == 'rejected' ? reason : '',
        suspensionReason: status == 'suspended' ? reason : '',
        clearRejection: status == 'approved',
        clearSuspension: status == 'approved',
      );
    }).toList();
    _products = _products
        .map((p) => p.vendorId == vendorId ? p.copyWith(vendorApprovalStatus: status) : p)
        .toList();
  }

  @override
  Future<void> setProductModeration(String productId, ProductModeration status, {String reason = ''}) async {
    _products = _products
        .map((p) => p.id == productId ? p.copyWith(moderation: status, rejectionReason: reason) : p)
        .toList();
  }

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {
    _customers = _customers.map((u) => u.id == userId ? u.copyWith(suspended: suspended) : u).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
  }

  @override
  Future<void> writeAudit({required String action, required String actorId, String? targetId, String? detail}) async {}
}
