import 'package:flutter/foundation.dart';

import '../../models/wishlist_item.dart';
import '../../services/session_service.dart';

class WishlistController extends ChangeNotifier {
  WishlistController(this._session) {
    _ids = _session.readWishlist();
  }

  final SessionService _session;
  List<String> _ids = [];

  List<String> get ids => List.unmodifiable(_ids);
  List<WishlistItem> get items =>
      _ids.map((id) => WishlistItem(productId: id, addedAt: DateTime.now())).toList();

  bool contains(String productId) => _ids.contains(productId);

  Future<void> toggle(String productId) async {
    if (_ids.contains(productId)) {
      _ids.remove(productId);
    } else {
      _ids.insert(0, productId);
    }
    await _session.writeWishlist(_ids);
    notifyListeners();
  }
}
