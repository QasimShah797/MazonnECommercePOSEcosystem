import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_mode.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/vendor.dart';

class SessionService {
  SessionService(this._prefs);

  final SharedPreferences _prefs;

  bool get onboardingComplete => _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  Future<void> completeOnboarding() => _prefs.setBool(StorageKeys.onboardingComplete, true);

  AppRole get role {
    final raw = _prefs.getString(StorageKeys.sessionRole);
    return AppRole.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppRole.guest,
    );
  }

  AppUser? get user {
    final raw = _prefs.getString(StorageKeys.sessionUser);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Vendor? get vendor {
    final raw = _prefs.getString(StorageKeys.sessionVendor);
    if (raw == null) return null;
    return Vendor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser user) async {
    await _prefs.setString(StorageKeys.sessionRole, AppRole.user.name);
    await _prefs.setString(StorageKeys.sessionUser, jsonEncode(user.toJson()));
    await _prefs.remove(StorageKeys.sessionVendor);
  }

  Future<void> saveVendor(Vendor vendor) async {
    await _prefs.setString(StorageKeys.sessionRole, AppRole.vendor.name);
    await _prefs.setString(StorageKeys.sessionVendor, jsonEncode(vendor.toJson()));
    await _prefs.remove(StorageKeys.sessionUser);
  }

  Future<void> clearSession() async {
    await _prefs.remove(StorageKeys.sessionRole);
    await _prefs.remove(StorageKeys.sessionUser);
    await _prefs.remove(StorageKeys.sessionVendor);
  }

  List<CartItem> readCart() {
    final raw = _prefs.getString(StorageKeys.cart);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeCart(List<CartItem> items) =>
      _prefs.setString(StorageKeys.cart, jsonEncode(items.map((e) => e.toJson()).toList()));

  List<String> readWishlist() => _prefs.getStringList(StorageKeys.wishlist) ?? [];

  Future<void> writeWishlist(List<String> ids) => _prefs.setStringList(StorageKeys.wishlist, ids);

  List<Address> readAddresses(List<Address> fallback) {
    final raw = _prefs.getString(StorageKeys.addresses);
    if (raw == null) return fallback;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeAddresses(List<Address> addresses) =>
      _prefs.setString(StorageKeys.addresses, jsonEncode(addresses.map((e) => e.toJson()).toList()));

  List<String> readRecentSearches() => _prefs.getStringList(StorageKeys.recentSearches) ?? [];

  Future<void> writeRecentSearches(List<String> values) =>
      _prefs.setStringList(StorageKeys.recentSearches, values);

  List<Order> readOrders(String key, List<Order> fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return List<Order>.from(fallback);
    final list = jsonDecode(raw) as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeOrders(String key, List<Order> orders) =>
      _prefs.setString(key, jsonEncode(orders.map((e) => e.toJson()).toList()));

  List<Product> readVendorProducts(List<Product> fallback) {
    final raw = _prefs.getString(StorageKeys.vendorProducts);
    if (raw == null) return List<Product>.from(fallback);
    final list = jsonDecode(raw) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeVendorProducts(List<Product> products) =>
      _prefs.setString(
        StorageKeys.vendorProducts,
        jsonEncode(products.map((e) => e.toJson()).toList()),
      );
}
