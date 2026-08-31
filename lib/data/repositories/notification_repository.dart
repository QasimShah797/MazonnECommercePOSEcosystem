import '../../models/catalog_extras.dart';
import '../mock/mock_catalog.dart';
import '../../services/session_service.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watch(String recipientId);
  Future<List<AppNotification>> fetch(String recipientId);
  Future<List<AppNotification>> fetchAll();
  Future<void> create(AppNotification notification);
  Future<void> markRead(String id);
  Future<void> markAllRead(String recipientId);
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(SessionService session) {
    // Session is accepted so tests and MazonnApp can share the same constructor shape.
    assert(session.onboardingComplete || !session.onboardingComplete);
  }

  final List<AppNotification> _items = List.of(MockCatalog.notifications);

  List<AppNotification> _for(String recipientId) {
    final filtered = _items.where((n) => n.recipientId.isEmpty || n.recipientId == recipientId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Stream<List<AppNotification>> watch(String recipientId) async* {
    yield _for(recipientId);
  }

  @override
  Future<List<AppNotification>> fetch(String recipientId) async => _for(recipientId);

  @override
  Future<List<AppNotification>> fetchAll() async {
    final copy = List<AppNotification>.from(_items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  @override
  Future<void> create(AppNotification notification) async {
    _items.removeWhere((n) => n.id == notification.id);
    _items.insert(0, notification);
  }

  @override
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(read: true);
  }

  @override
  Future<void> markAllRead(String recipientId) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].recipientId == recipientId || _items[i].recipientId.isEmpty) {
        _items[i] = _items[i].copyWith(read: true);
      }
    }
  }
}
