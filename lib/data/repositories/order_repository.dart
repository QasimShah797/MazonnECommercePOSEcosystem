import '../../core/constants/app_constants.dart';
import '../../models/order.dart';
import '../mock/mock_catalog.dart';
import '../../services/session_service.dart';

abstract class OrderRepository {
  Future<List<Order>> fetchUserOrders();
  Future<List<Order>> fetchVendorOrders();
  Future<Order> placeOrder(Order order);
  Future<Order> updateStatus(String id, OrderStatus status);
}

class MockOrderRepository implements OrderRepository {
  MockOrderRepository(this._session);

  final SessionService _session;

  Future<void> _delay() => Future<void>.delayed(AppConstants.mockNetworkDelay);

  @override
  Future<List<Order>> fetchUserOrders() async {
    await _delay();
    return _session.readOrders(StorageKeys.userOrders, MockCatalog.seedOrders);
  }

  @override
  Future<List<Order>> fetchVendorOrders() async {
    await _delay();
    return _session.readOrders(StorageKeys.vendorOrders, MockCatalog.seedOrders);
  }

  @override
  Future<Order> placeOrder(Order order) async {
    await _delay();
    final userOrders = _session.readOrders(StorageKeys.userOrders, MockCatalog.seedOrders);
    final vendorOrders = _session.readOrders(StorageKeys.vendorOrders, MockCatalog.seedOrders);
    userOrders.insert(0, order);
    vendorOrders.insert(0, order);
    await _session.writeOrders(StorageKeys.userOrders, userOrders);
    await _session.writeOrders(StorageKeys.vendorOrders, vendorOrders);
    return order;
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    await _delay();
    Order updated = MockCatalog.seedOrders.first;

    Future<List<Order>> patch(String key) async {
      final list = _session.readOrders(key, MockCatalog.seedOrders);
      final index = list.indexWhere((o) => o.id == id);
      if (index >= 0) {
        updated = list[index].copyWith(
          status: status,
          trackingCode: status == OrderStatus.shipped
              ? (list[index].trackingCode ?? 'MAZ-${id.hashCode.abs() % 99999}')
              : list[index].trackingCode,
        );
        list[index] = updated;
        await _session.writeOrders(key, list);
      }
      return list;
    }

    await patch(StorageKeys.userOrders);
    await patch(StorageKeys.vendorOrders);
    return updated;
  }
}
