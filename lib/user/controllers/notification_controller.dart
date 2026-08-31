import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/notification_repository.dart';
import '../../models/catalog_extras.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _sub;
  List<AppNotification> _items = [];
  bool _loading = false;
  String? _boundId;

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  int get unreadCount => _items.where((n) => !n.read).length;

  void bind(String recipientId) {
    if (recipientId.isEmpty || recipientId == _boundId) return;
    _boundId = recipientId;
    _loading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _repository.watch(recipientId).listen((list) {
      _items = list;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> load(String recipientId) async {
    _loading = true;
    notifyListeners();
    _items = await _repository.fetch(recipientId);
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    final index = _items.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> markAllRead(String recipientId) async {
    await _repository.markAllRead(recipientId);
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }
}
