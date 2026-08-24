import 'package:flutter/foundation.dart';

import '../../data/mock/mock_catalog.dart';
import '../../models/address.dart';
import '../../services/session_service.dart';

class AddressController extends ChangeNotifier {
  AddressController(this._session) {
    _addresses = _session.readAddresses(MockCatalog.addresses);
  }

  final SessionService _session;
  List<Address> _addresses = [];
  String? _selectedId;

  List<Address> get addresses => List.unmodifiable(_addresses);

  Address? get selected {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.id == (_selectedId ?? _addresses.firstWhere((e) => e.isDefault, orElse: () => _addresses.first).id),
      orElse: () => _addresses.first,
    );
  }

  void select(String id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<void> save(Address address) async {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    var next = List<Address>.from(_addresses);
    if (address.isDefault) {
      next = next.map((a) => a.copyWith(isDefault: false)).toList();
    }
    if (index >= 0) {
      next[index] = address;
    } else {
      next.add(address);
    }
    _addresses = next;
    await _session.writeAddresses(_addresses);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    await _session.writeAddresses(_addresses);
    notifyListeners();
  }
}
