import '../../core/constants/app_constants.dart';
import '../../core/utils/order_notifications.dart';
import '../../models/order.dart';
import '../../services/session_service.dart';
import '../mock/mock_catalog.dart';
import 'notification_repository.dart';

abstract class OrderRepository {
  Future<List<Order>> fetchUserOrders();
  Future<List<Order>> fetchVendorOrders();
  Future<List<Order>> fetchAllOrders();
  Stream<List<Order>> watchUserOrders();
  Stream<List<Order>> watchVendorOrders();
  Future<Order> placeOrder(Order order);
  Future<Order> updateStatus(String id, OrderStatus status);
}

class MockOrderRepository implements OrderRepository {
  MockOrderRepository(this._session, {NotificationRepository? notifications})
      : _notifications = notifications;

  final SessionService _session;
  final NotificationRepository? _notifications;

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
  Future<List<Order>> fetchAllOrders() async {
    await _delay();
    return _session.readOrders(StorageKeys.vendorOrders, MockCatalog.seedOrders);
  }

  @override
  Stream<List<Order>> watchUserOrders() async* {
    yield await fetchUserOrders();
  }

  @override
  Stream<List<Order>> watchVendorOrders() async* {
    yield await fetchVendorOrders();
  }

  @override
  Future<Order> placeOrder(Order order) async {
    await _delay();
    final pending = order.copyWith(status: OrderStatus.pending);
    final userOrders = _session.readOrders(StorageKeys.userOrders, MockCatalog.seedOrders);
    final vendorOrders = _session.readOrders(StorageKeys.vendorOrders, MockCatalog.seedOrders);
    userOrders.insert(0, pending);
    vendorOrders.insert(0, pending);
    await _session.writeOrders(StorageKeys.userOrders, userOrders);
    await _session.writeOrders(StorageKeys.vendorOrders, vendorOrders);
    await _emitPlacement(pending);
    return pending;
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    await _delay();
    Order? updated;

    Future<void> patch(String key) async {
      final list = _session.readOrders(key, MockCatalog.seedOrders);
      final index = list.indexWhere((o) => o.id == id);
      if (index < 0) return;
      final current = list[index];
      if (!OrderTransitions.canTransition(current.status, status)) {
        throw StateError('Cannot change ${current.status.label} orders to ${status.label}.');
      }
      updated = current.copyWith(
        status: status,
        trackingCode: status == OrderStatus.shipped
            ? (current.trackingCode ?? 'MAZ-${id.hashCode.abs() % 99999}')
            : current.trackingCode,
      );
      list[index] = updated!;
      await _session.writeOrders(key, list);
    }

    await patch(StorageKeys.userOrders);
    await patch(StorageKeys.vendorOrders);
    if (updated == null) throw StateError('Order not found');
    await _emitStatus(updated!);
    return updated!;
  }

  Future<void> _emitPlacement(Order order) async {
    final repo = _notifications;
    if (repo == null) return;
    await repo.create(OrderNotificationCopy.vendorNewOrder(order));
    await repo.create(
      OrderNotificationCopy.customerUpdate(
        order,
        'order_placed',
        OrderNotificationCopy.customerBody('order_placed', order.id),
      ),
    );
  }

  Future<void> _emitStatus(Order order) async {
    final repo = _notifications;
    if (repo == null) return;
    await repo.create(
      OrderNotificationCopy.customerUpdate(
        order,
        OrderNotificationCopy.typeForStatus(order.status),
        OrderNotificationCopy.customerBodyForStatus(order.status, order.id),
      ),
    );
  }
}
