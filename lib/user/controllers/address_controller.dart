import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../models/address.dart';
import '../../services/session_service.dart';

class AddressController extends ChangeNotifier {
  AddressController(this._session) {
    final stored = _session.readAddresses(const []);
    _addresses = stored.where((a) => !a.isLegacyForeign).toList();
    if (_addresses.length != stored.length) {
      _session.writeAddresses(_addresses);
    }
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
    final nextAddress = address.copyWith(
      country: address.country.trim().isEmpty ? AppConstants.defaultCountry : address.country,
    );
    final index = _addresses.indexWhere((a) => a.id == nextAddress.id);
    var next = List<Address>.from(_addresses);
    if (nextAddress.isDefault) {
      next = next.map((a) => a.copyWith(isDefault: false)).toList();
    }
    if (index >= 0) {
      next[index] = nextAddress;
    } else {
      next.add(nextAddress);
    }
    _addresses = next;
    _selectedId = nextAddress.id;
    await _session.writeAddresses(_addresses);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedId == id) _selectedId = null;
    await _session.writeAddresses(_addresses);
    notifyListeners();
  }
}
