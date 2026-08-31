import 'package:flutter/foundation.dart';

import '../../core/constants/app_mode.dart';
import '../../core/errors/auth_failure.dart';
import '../../core/firebase/mazonn_firebase.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import '../../services/session_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required SessionService session,
  })  : _authRepository = authRepository,
        _session = session {
    _role = session.role;
    _user = session.user;
    _vendor = session.vendor;
    _onboardingComplete = session.onboardingComplete;
  }

  final AuthRepository _authRepository;
  final SessionService _session;

  AppRole _role = AppRole.guest;
  AppUser? _user;
  Vendor? _vendor;
  bool _onboardingComplete = false;
  bool _busy = false;
  String? _error;

  AppRole get role => _role;
  AppUser? get user => _user;
  Vendor? get vendor => _vendor;
  bool get onboardingComplete => _onboardingComplete;
  bool get busy => _busy;
  String? get error => _error;
  bool get isUser => _role == AppRole.user && _user != null;
  bool get isVendor => _role == AppRole.vendor && _vendor != null;
  bool get isAdmin => _role == AppRole.admin && _user != null;
  bool get isAuthenticated => isUser || isVendor || isAdmin;
  bool get vendorCanSell => _vendor?.canSell ?? false;

  String get recipientId => _vendor?.id ?? _user?.id ?? '';

  void _applyUser(AppUser user) {
    if (user.suspended) {
      throw const AuthFailure('This account has been suspended.');
    }
    _user = user;
    _vendor = null;
    _role = user.role == 'admin' ? AppRole.admin : AppRole.user;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _session.completeOnboarding();
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    try {
      final vendor = await _authRepository.restoreVendor();
      if (vendor != null) {
        await _session.saveVendor(vendor);
        _vendor = vendor;
        _user = null;
        _role = AppRole.vendor;
        notifyListeners();
        return;
      }
      final user = await _authRepository.restoreUser();
      if (user != null) {
        if (user.role == 'vendor') {
          // Vendor restore is handled above; keep going only for shop/admin users.
        }
        await _session.saveUser(user);
        _applyUser(user);
        notifyListeners();
        return;
      }
      if (MazonnFirebase.isReady && (_user != null || _vendor != null)) {
        await _session.clearSession();
        _user = null;
        _vendor = null;
        _role = AppRole.guest;
        notifyListeners();
      }
    } catch (_) {
      // Keep any cached session if restore fails while offline.
    }
  }

  Future<bool> loginUser(String email, String password) async {
    return _run(() async {
      final user = await _authRepository.loginUser(email: email, password: password);
      await _session.saveUser(user);
      _applyUser(user);
    });
  }

  Future<bool> loginWithGoogle() async {
    return _run(() async {
      final user = await _authRepository.signInWithGoogle();
      await _session.saveUser(user);
      _applyUser(user);
    });
  }

  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _run(() async {
      final user = await _authRepository.registerUser(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      await _session.saveUser(user);
      _applyUser(user);
    });
  }

  Future<bool> loginVendor(String email, String password) async {
    return _run(() async {
      final vendor = await _authRepository.loginVendor(email: email, password: password);
      await _session.saveVendor(vendor);
      _vendor = vendor;
      _user = null;
      _role = AppRole.vendor;
    });
  }

  Future<bool> registerVendor({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required String category,
    required String address,
    String cnic = '',
    String bankName = '',
    String accountTitle = '',
    String accountNumber = '',
    String iban = '',
  }) async {
    return _run(() async {
      final vendor = await _authRepository.registerVendor(
        businessName: businessName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        password: password,
        category: category,
        address: address,
        cnic: cnic,
        bankName: bankName,
        accountTitle: accountTitle,
        accountNumber: accountNumber,
        iban: iban,
      );
      await _session.saveVendor(vendor);
      _vendor = vendor;
      _user = null;
      _role = AppRole.vendor;
    });
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _authRepository.sendPasswordReset(email));
  }

  Future<void> updateUser(AppUser user) async {
    _user = user;
    await _session.saveUser(user);
    await _authRepository.updateUserProfile(user);
    notifyListeners();
  }

  Future<void> updateVendor(Vendor vendor) async {
    _vendor = vendor;
    await _session.saveVendor(vendor);
    await _authRepository.updateVendorProfile(vendor);
    notifyListeners();
  }

  Future<void> reloadVendor() async {
    final vendor = await _authRepository.restoreVendor();
    if (vendor == null) return;
    _vendor = vendor;
    await _session.saveVendor(vendor);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _session.clearSession();
    _user = null;
    _vendor = null;
    _role = AppRole.guest;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      if (e.cancelled) return false;
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
