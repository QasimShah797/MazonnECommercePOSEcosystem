import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/mazonn_firebase.dart';
import '../../models/catalog_extras.dart';
import 'notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('notifications');

  AppNotification _from(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = data['id'] ?? doc.id;
    return AppNotification.fromJson(data);
  }

  List<AppNotification> _sorted(Iterable<AppNotification> items) {
    final list = items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<AppNotification>> watch(String recipientId) {
    if (!MazonnFirebase.isReady || recipientId.isEmpty) {
      return Stream.value(const []);
    }
    return _col.where('recipientId', isEqualTo: recipientId).snapshots().map(
          (snap) => _sorted(snap.docs.map(_from)),
        );
  }

  @override
  Future<List<AppNotification>> fetch(String recipientId) async {
    if (!MazonnFirebase.isReady || recipientId.isEmpty) return [];
    final snap = await _col.where('recipientId', isEqualTo: recipientId).get();
    return _sorted(snap.docs.map(_from));
  }

  @override
  Future<List<AppNotification>> fetchAll() async {
    if (!MazonnFirebase.isReady) return [];
    final snap = await _col.limit(200).get();
    return _sorted(snap.docs.map(_from));
  }

  @override
  Future<void> create(AppNotification notification) async {
    if (!MazonnFirebase.isReady) return;
    await _col.doc(notification.id).set(notification.toJson());
  }

  @override
  Future<void> markRead(String id) async {
    if (!MazonnFirebase.isReady) return;
    await _col.doc(id).set({'read': true}, SetOptions(merge: true));
  }

  @override
  Future<void> markAllRead(String recipientId) async {
    if (!MazonnFirebase.isReady) return;
    final snap = await _col.where('recipientId', isEqualTo: recipientId).where('read', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
