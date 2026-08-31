
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../core/firebase/mazonn_firebase.dart';
import '../../models/catalog_extras.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import 'admin_repository.dart';

class FirebaseAdminRepository implements AdminRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AdminSnapshot> load() async {
    if (!MazonnFirebase.isReady) return MockAdminRepository().load();
    final vendors = await _db.collection('vendors').get();
    final products = await _db.collection('products').limit(400).get();
    final orders = await _db.collection('orders').limit(400).get();
    final users = await _db.collection('users').limit(400).get();
    final notes = await _db.collection('notifications').limit(200).get();
    return AdminSnapshot(
      vendors: vendors.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = data['id'] ?? d.id;
        return Vendor.fromJson(data);
      }).toList(),
      products: products.docs.map((d) => Product.fromJson(d.data())).toList(),
      orders: orders.docs.map((d) => Order.fromJson(d.data())).toList()
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt)),
      customers: users.docs
          .map((d) => AppUser.fromJson(d.data()))
          .where((u) => u.role != 'admin')
          .toList(),
      notifications: notes.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = data['id'] ?? d.id;
        return AppNotification.fromJson(data);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<void> setVendorStatus(String vendorId, String status, {String reason = '', String actorId = '', String actorName = ''}) async {
    if (!MazonnFirebase.isReady) return;
    final now = DateTime.now();
    final vendorRef = _db.collection('vendors').doc(vendorId);
    final action = switch (status) {
      'approved' => 'approved',
      'rejected' => 'rejected',
      'suspended' => 'suspended',
      'pending' => 'resubmitted',
      _ => status,
    };
    await vendorRef.set({
      'approvalStatus': status,
      'rejectionReason': status == 'rejected' ? reason : '',
      'suspensionReason': status == 'suspended' ? reason : '',
      'reviewedAt': now.toIso8601String(),
      'reviewedBy': actorId,
      'reviewedByName': actorName,
      'history': FieldValue.arrayUnion([
        {
          'at': now.toIso8601String(),
          'action': action,
          'actorId': actorId,
          'actorName': actorName.isEmpty ? 'Super Admin' : actorName,
          'detail': reason,
        }
      ]),
    }, SetOptions(merge: true));

    final products = await _db.collection('products').where('vendorId', isEqualTo: vendorId).get();
    if (products.docs.isNotEmpty) {
      var batch = _db.batch();
      var count = 0;
      for (final doc in products.docs) {
        batch.set(doc.reference, {'vendorApprovalStatus': status}, SetOptions(merge: true));
        count++;
        if (count >= 450) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }

    final (title, body) = switch (status) {
      'approved' => (
          'You are approved to sell',
          'Your vendor account has been approved. You can now publish products, receive orders, and access earnings on Mazonn.',
        ),
      'rejected' => (
          'Application not approved',
          reason.isEmpty
              ? 'Your submitted information could not be verified. Please update your documents and resubmit.'
              : reason,
        ),
      'suspended' => (
          'Account suspended',
          reason.isEmpty ? 'Your vendor account has been suspended. Selling is disabled until Super Admin reactivates it.' : reason,
        ),
      _ => ('Vendor status updated', 'Your vendor status is now $status.'),
    };
    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'createdAt': now.toIso8601String(),
      'recipientId': vendorId,
      'type': 'vendor_status',
      'read': false,
    });
  }

  @override
  Future<void> setProductModeration(String productId, ProductModeration status, {String reason = ''}) async {
    if (!MazonnFirebase.isReady) return;
    await _db.collection('products').doc(productId).set({
      'moderation': status.name,
      'rejectionReason': reason,
      'isActive': status == ProductModeration.approved,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {
    if (!MazonnFirebase.isReady) return;
    await _db.collection('users').doc(userId).set({'suspended': suspended}, SetOptions(merge: true));
  }

  @override
  Future<void> saveProduct(Product product) async {
    if (!MazonnFirebase.isReady) return;
    await _db.collection('products').doc(product.id).set(product.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> writeAudit({
    required String action,
    required String actorId,
    String? targetId,
    String? detail,
  }) async {
    if (!MazonnFirebase.isReady) return;
    await _db.collection('auditLogs').add({
      'action': action,
      'actorId': actorId,
      'targetId': targetId,
      'detail': detail,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
