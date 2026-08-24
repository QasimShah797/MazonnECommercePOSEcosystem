import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase/mazonn_firebase.dart';
import '../../models/order.dart';
import 'order_repository.dart';

class FirebaseOrderRepository implements OrderRepository {
  CollectionReference<Map<String, dynamic>> get _orders =>
      FirebaseFirestore.instance.collection('orders');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<List<Order>> fetchUserOrders() async {
    if (!MazonnFirebase.isReady || _uid == null) return [];
    final snapshot = await _orders.where('customerId', isEqualTo: _uid).get();
    final list = snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return list;
  }

  @override
  Future<List<Order>> fetchVendorOrders() async {
    if (!MazonnFirebase.isReady || _uid == null) return [];
    final snapshot = await _orders.where('vendorId', isEqualTo: _uid).get();
    final list = snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return list;
  }

  @override
  Future<Order> placeOrder(Order order) async {
    if (!MazonnFirebase.isReady) return order;
    await _orders.doc(order.id).set(order.toJson());
    return order;
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    if (!MazonnFirebase.isReady) throw StateError('Firebase is not ready');
    final doc = await _orders.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Order not found');
    }
    final current = Order.fromJson(doc.data()!);
    final updated = current.copyWith(
      status: status,
      trackingCode: status == OrderStatus.shipped
          ? (current.trackingCode ?? 'MAZ-${id.hashCode.abs() % 99999}')
          : current.trackingCode,
    );
    await _orders.doc(id).set(updated.toJson());
    return updated;
  }
}
