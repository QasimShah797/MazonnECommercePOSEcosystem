import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/auth_failure.dart';
import '../../core/firebase/mazonn_firebase.dart';
import '../../data/mock/mock_catalog.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth {
    _ensureReady();
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _db {
    _ensureReady();
    return FirebaseFirestore.instance;
  }

  void _ensureReady() {
    if (!MazonnFirebase.isReady) {
      throw const AuthFailure(
        'Mazonn is not connected to Firebase yet. Add google-services.json and run flutterfire configure, then restart the app.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _vendors => _db.collection('vendors');

  @override
  Future<AppUser> loginUser({required String email, required String password}) async {
    final trimmed = email.trim();
    if (_isDemoAdmin(trimmed, password)) {
      return _signInOrCreateDemoAdmin();
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthFailure('Unable to sign in.');
      final user = await _readOrCreateUser(
        uid: uid,
        email: trimmed,
        fallbackName: credential.user?.displayName,
      );
      await MazonnFirebase.seedCatalogIfNeeded();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  bool _isDemoAdmin(String email, String password) =>
      email.toLowerCase() == AppConstants.demoAdminEmail && password == AppConstants.demoAdminPassword;

  Future<AppUser> _signInOrCreateDemoAdmin() async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: AppConstants.demoAdminEmail,
        password: AppConstants.demoAdminPassword,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) throw const AuthFailure('Unable to sign in.');
      return await _writeDemoAdmin(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' && e.code != 'wrong-password' && e.code != 'invalid-credential') {
        throw AuthFailure(_messageFor(e));
      }
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: AppConstants.demoAdminEmail,
        password: AppConstants.demoAdminPassword,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) throw const AuthFailure('Unable to create the Super Admin account.');
      await firebaseUser.updateDisplayName(MockCatalog.demoAdmin.fullName);
      return await _writeDemoAdmin(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthFailure(
          'admin@mazonn.app already exists in Firebase with a different password. In Firebase Console → Authentication, set that user’s password to admin123, then try again.',
        );
      }
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<AppUser> _writeDemoAdmin(String uid) async {
    final demo = MockCatalog.demoAdmin;
    final user = AppUser(
      id: uid,
      fullName: demo.fullName,
      email: AppConstants.demoAdminEmail,
      phone: demo.phone,
      avatarLabel: demo.avatarLabel,
      city: demo.city,
      role: 'admin',
    );
    await _users.doc(uid).set({...user.toJson(), 'role': 'admin'}, SetOptions(merge: true));
    await MazonnFirebase.seedCatalogIfNeeded();
    return user;
  }

  @override
  Future<AppUser> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthFailure('Unable to create your account.');
      await credential.user?.updateDisplayName(fullName.trim());
      final user = AppUser(
        id: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        avatarLabel: _initials(fullName),
      );
      await _users.doc(uid).set({...user.toJson(), 'role': user.role});
      await MazonnFirebase.seedCatalogIfNeeded();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      if (Firebase.apps.isEmpty) {
        throw const AuthFailure(
          'Mazonn is not connected to Firebase yet. Add google-services.json and run flutterfire configure, then restart the app.',
        );
      }
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: AppConstants.googleWebClientId,
        );
      } catch (_) {}
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure('Google sign-in is not available on this device.');
      }
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google did not return a sign-in token. Add your Web client ID and try again.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) throw const AuthFailure('Unable to sign in with Google.');
      final user = await _readOrCreateUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? googleUser.email,
        fallbackName: firebaseUser.displayName ?? googleUser.displayName,
      );
      await MazonnFirebase.seedCatalogIfNeeded();
      return user;
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure.cancelled();
      }
      throw AuthFailure(_googleMessage(e));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw const AuthFailure(
          'Google sign-in is disabled in Firebase. Enable Google under Authentication → Sign-in method.',
        );
      }
      throw AuthFailure(_messageFor(e));
    } catch (e) {
      throw AuthFailure(e.toString().contains('YOUR_API_KEY')
          ? 'Firebase is not configured. Connect this app to your Firebase project first.'
          : 'Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<Vendor> loginVendor({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthFailure('Unable to sign in.');
      final vendor = await _readVendor(uid);
      if (vendor == null) {
        throw const AuthFailure('This account is not registered as a vendor. Register your studio first.');
      }
      await MazonnFirebase.seedCatalogIfNeeded();
      return vendor;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<Vendor> registerVendor({
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw const AuthFailure('Unable to create your vendor account.');
      await credential.user?.updateDisplayName(ownerName.trim());
      final now = DateTime.now();
      final vendor = Vendor(
        id: uid,
        businessName: businessName.trim(),
        ownerName: ownerName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        category: category,
        address: address.trim(),
        approvalStatus: 'pending',
        logoLabel: _initials(businessName),
        cnic: cnic.trim(),
        bankName: bankName.trim(),
        accountTitle: accountTitle.trim(),
        accountNumber: accountNumber.trim(),
        iban: iban.trim(),
        registeredAt: now,
        history: [
          VendorHistoryEntry(
            at: now,
            action: 'registered',
            actorId: uid,
            actorName: ownerName.trim(),
            detail: 'Vendor account created and waiting for Super Admin approval.',
          ),
        ],
      );
      await _vendors.doc(uid).set(vendor.toJson());
      await _users.doc(uid).set({
        'id': uid,
        'fullName': ownerName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'avatarLabel': _initials(ownerName),
        'city': 'Karachi',
        'role': 'vendor',
      });
      await _db.collection('notifications').add({
        'title': 'Application received',
        'body':
            'Your vendor account is under review. You will be able to sell on the platform after Super Admin approval.',
        'createdAt': now.toIso8601String(),
        'recipientId': uid,
        'type': 'vendor_status',
        'read': false,
      });
      await MazonnFirebase.seedCatalogIfNeeded();
      return vendor;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    if (MazonnFirebase.isReady) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Future<void> updateUserProfile(AppUser user) async {
    if (!MazonnFirebase.isReady) return;
    await _users.doc(user.id).set({...user.toJson(), 'role': user.role}, SetOptions(merge: true));
  }

  @override
  Future<void> updateVendorProfile(Vendor vendor) async {
    if (!MazonnFirebase.isReady) return;
    await _vendors.doc(vendor.id).set(vendor.toJson(), SetOptions(merge: true));
  }

  @override
  Future<AppUser?> restoreUser() async {
    if (!MazonnFirebase.isReady) return null;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return _readOrCreateUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      fallbackName: firebaseUser.displayName,
    );
  }

  @override
  Future<Vendor?> restoreVendor() async {
    if (!MazonnFirebase.isReady) return null;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return _readVendor(firebaseUser.uid);
  }

  Future<AppUser> _readOrCreateUser({
    required String uid,
    required String email,
    String? fallbackName,
  }) async {
    final snapshot = await _users.doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUser.fromJson(snapshot.data()!);
    }
    final name = (fallbackName == null || fallbackName.trim().isEmpty)
        ? (email.split('@').first)
        : fallbackName.trim();
    final user = AppUser(
      id: uid,
      fullName: name,
      email: email,
      phone: '',
      avatarLabel: _initials(name),
    );
    await _users.doc(uid).set({...user.toJson(), 'role': 'user'});
    return user;
  }

  Future<Vendor?> _readVendor(String uid) async {
    final snapshot = await _vendors.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    data['id'] = data['id'] ?? uid;
    return Vendor.fromJson(data);
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account exists for this email.',
      'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Use a stronger password (at least 6 characters).',
      'network-request-failed' => 'Check your internet connection and try again.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'operation-not-allowed' => 'This sign-in method is disabled in Firebase.',
      _ => error.message ?? 'Something went wrong. Please try again.',
    };
  }

  String _googleMessage(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
        error.code == GoogleSignInExceptionCode.providerConfigurationError ||
        error.description?.contains('ApiException: 10') == true ||
        error.description?.contains('DEVELOPER_ERROR') == true ||
        error.description?.contains('serverClientId') == true) {
      return 'Google sign-in is missing its Android setup. Fully restart the app after google-services.json is updated.';
    }
    return error.description ?? 'Google sign-in failed. Please try again.';
  }
}
