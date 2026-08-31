import '../../models/catalog_extras.dart';
import '../../models/order.dart';

abstract final class OrderNotificationCopy {
  static String customerTitle(String type, String orderId) => switch (type) {
        'order_placed' => 'Order placed',
        'order_accepted' => 'Order accepted',
        'processing' => 'Order processing',
        'shipped' => 'Order shipped',
        'delivered' => 'Order delivered',
        'rejected' => 'Order rejected',
        'cancelled' => 'Order cancelled',
        _ => 'Order update',
      };

  static String customerBody(String type, String orderId) => switch (type) {
        'order_placed' => 'Your order #$orderId has been placed.',
        'order_accepted' => 'Your order #$orderId has been accepted.',
        'processing' => 'Your order #$orderId is being prepared.',
        'shipped' => 'Your order #$orderId has been shipped.',
        'delivered' => 'Your order #$orderId has been delivered.',
        'rejected' => 'Your order #$orderId was rejected.',
        'cancelled' => 'Your order #$orderId was cancelled.',
        _ => 'Your order #$orderId was updated.',
      };

  static String customerBodyForStatus(OrderStatus status, String orderId) => switch (status) {
        OrderStatus.pending => customerBody('order_placed', orderId),
        OrderStatus.processing => 'Your order has been accepted and is now being processed.',
        OrderStatus.shipped => customerBody('shipped', orderId),
        OrderStatus.delivered => customerBody('delivered', orderId),
        OrderStatus.rejected => 'Unfortunately, your order has been rejected by the vendor.',
        OrderStatus.cancelled => customerBody('cancelled', orderId),
      };

  static String typeForStatus(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'order_placed',
        OrderStatus.processing => 'order_accepted',
        OrderStatus.shipped => 'shipped',
        OrderStatus.delivered => 'delivered',
        OrderStatus.rejected => 'rejected',
        OrderStatus.cancelled => 'cancelled',
      };

  static AppNotification vendorNewOrder(Order order) {
    return AppNotification(
      id: 'n_${order.id}_vendor',
      title: 'New Order Received',
      body:
          'NEW ORDER #${order.id}\n${order.itemCount} Items\nTotal: ${order.total.toStringAsFixed(0)}\nPayment: ${order.paymentMethod}',
      createdAt: DateTime.now(),
      recipientId: order.vendorId,
      type: 'new_order',
      orderId: order.id,
    );
  }

  static AppNotification customerUpdate(Order order, String type, String body) {
    return AppNotification(
      id: 'n_${order.id}_$type',
      title: customerTitle(type, order.id),
      body: body,
      createdAt: DateTime.now(),
      recipientId: order.customerId,
      type: type,
      orderId: order.id,
    );
  }
}
