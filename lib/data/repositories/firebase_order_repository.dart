import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase/mazonn_firebase.dart';
import '../../core/utils/order_notifications.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import 'notification_repository.dart';
import 'order_repository.dart';

class FirebaseOrderRepository implements OrderRepository {
  FirebaseOrderRepository({NotificationRepository? notifications}) : _notifications = notifications;

  final NotificationRepository? _notifications;

  CollectionReference<Map<String, dynamic>> get _orders =>
      FirebaseFirestore.instance.collection('orders');
  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<Order> _parse(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return list;
  }

  @override
  Future<List<Order>> fetchUserOrders() async {
    if (!MazonnFirebase.isReady || _uid == null) return [];
    final snapshot = await _orders.where('customerId', isEqualTo: _uid).get();
    return _parse(snapshot);
  }

  @override
  Future<List<Order>> fetchVendorOrders() async {
    if (!MazonnFirebase.isReady || _uid == null) return [];
    final snapshot = await _orders.where('vendorId', isEqualTo: _uid).get();
    return _parse(snapshot);
  }

  @override
  Future<List<Order>> fetchAllOrders() async {
    if (!MazonnFirebase.isReady) return [];
    final snapshot = await _orders.limit(300).get();
    return _parse(snapshot);
  }

  @override
  Stream<List<Order>> watchUserOrders() {
    if (!MazonnFirebase.isReady || _uid == null) return Stream.value(const []);
    return _orders.where('customerId', isEqualTo: _uid).snapshots().map(_parse);
  }

  @override
  Stream<List<Order>> watchVendorOrders() {
    if (!MazonnFirebase.isReady || _uid == null) return Stream.value(const []);
    return _orders.where('vendorId', isEqualTo: _uid).snapshots().map(_parse);
  }

  @override
  Future<Order> placeOrder(Order order) async {
    if (!MazonnFirebase.isReady) return order.copyWith(status: OrderStatus.pending);
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in to place an order.');
    }
    final priced = (await _serverQuote(order)).copyWith(customerId: uid);
    await _orders.doc(priced.id).set(priced.toJson());
    await _notifications?.create(OrderNotificationCopy.vendorNewOrder(priced));
    await _notifications?.create(
      OrderNotificationCopy.customerUpdate(
        priced,
        'order_placed',
        OrderNotificationCopy.customerBody('order_placed', priced.id),
      ),
    );
    return priced;
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    if (!MazonnFirebase.isReady) throw StateError('Firebase is not ready');
    final doc = await _orders.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Order not found');
    }
    final current = Order.fromJson(doc.data()!);
    if (!OrderTransitions.canTransition(current.status, status)) {
      throw StateError('Cannot change ${current.status.label} orders to ${status.label}.');
    }
    final uid = _uid;
    final isParty = uid != null && (current.customerId == uid || current.vendorId == uid);
    if (!isParty) {
      throw StateError('You are not allowed to update this order.');
    }
    if (status == OrderStatus.cancelled && current.customerId != uid && current.vendorId != uid) {
      throw StateError('You are not allowed to cancel this order.');
    }
    final updated = current.copyWith(
      status: status,
      trackingCode: status == OrderStatus.shipped
          ? (current.trackingCode ?? 'MAZ-${id.hashCode.abs() % 99999}')
          : current.trackingCode,
    );
    await _orders.doc(id).set(updated.toJson());
    await _notifications?.create(
      OrderNotificationCopy.customerUpdate(
        updated,
        OrderNotificationCopy.typeForStatus(status),
        OrderNotificationCopy.customerBodyForStatus(status, updated.id),
      ),
    );
    return updated;
  }

  Future<Order> _serverQuote(Order incoming) async {
    if (incoming.items.isEmpty) {
      throw StateError('Your bag is empty.');
    }
    final quotedItems = <OrderItem>[];
    var subtotal = 0.0;
    var bulkDiscount = 0.0;
    for (final item in incoming.items) {
      Product? product;
      try {
        final snap = await _products.doc(item.productId).get();
        if (snap.exists && snap.data() != null) {
          product = Product.fromJson(snap.data()!);
        }
      } catch (_) {
        product = null;
      }
      if (product == null) {
        quotedItems.add(item);
        subtotal += item.lineSubtotal;
        bulkDiscount += item.bulkDiscount;
        continue;
      }
      if (!product.isMarketplaceVisible) {
        throw StateError('${product.name} is no longer available.');
      }
      if (item.quantity > product.stock) {
        throw StateError('${product.name} does not have enough stock.');
      }
      final quote = product.quote(item.quantity);
      quotedItems.add(
        OrderItem(
          productId: product.id,
          name: product.name,
          brand: product.brand,
          price: product.price,
          quantity: item.quantity,
          visualSeed: product.visualSeed,
          color: item.color,
          size: item.size,
          imageUrl: product.primaryImage,
          bulkDiscount: quote.discount,
        ),
      );
      subtotal += quote.subtotal;
      bulkDiscount += quote.discount;
    }
    final coupon = incoming.couponDiscount;
    final delivery = incoming.deliveryFee;
    final total = (subtotal - bulkDiscount - coupon + delivery).clamp(0, double.infinity).toDouble();
    return Order(
      id: incoming.id,
      placedAt: incoming.placedAt,
      items: quotedItems,
      status: OrderStatus.pending,
      subtotal: subtotal,
      discount: bulkDiscount + coupon,
      deliveryFee: delivery,
      total: total,
      addressLabel: incoming.addressLabel,
      addressLine: incoming.addressLine,
      deliveryMethod: incoming.deliveryMethod,
      paymentMethod: incoming.paymentMethod,
      vendorId: incoming.vendorId,
      vendorName: incoming.vendorName,
      customerName: incoming.customerName,
      customerId: incoming.customerId,
      couponDiscount: coupon,
    );
  }
}
