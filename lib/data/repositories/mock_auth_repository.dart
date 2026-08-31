import '../../core/constants/app_constants.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import '../mock/mock_catalog.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  Future<void> _delay() => Future<void>.delayed(AppConstants.mockNetworkDelay);

  @override
  Future<AppUser> loginUser({required String email, required String password}) async {
    await _delay();
    if (email.trim().toLowerCase() == AppConstants.demoAdminEmail &&
        password == AppConstants.demoAdminPassword) {
      return MockCatalog.demoAdmin;
    }
    if (email.trim().toLowerCase() == AppConstants.demoUserEmail &&
        password == AppConstants.demoUserPassword) {
      return MockCatalog.demoUser;
    }
    return AppUser(
      id: 'user_${email.hashCode}',
      fullName: email.split('@').first.replaceAll('.', ' '),
      email: email.trim(),
      phone: '+1 415 555 0100',
      avatarLabel: email.substring(0, 1).toUpperCase(),
    );
  }

  @override
  Future<AppUser> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _delay();
    return AppUser(
      id: 'user_${email.hashCode}',
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      avatarLabel: fullName.trim().isEmpty ? 'M' : fullName.trim()[0].toUpperCase(),
    );
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await _delay();
    return MockCatalog.demoUser;
  }

  @override
  Future<void> sendPasswordReset(String email) => _delay();

  @override
  Future<Vendor> loginVendor({required String email, required String password}) async {
    await _delay();
    if (email.trim().toLowerCase() == AppConstants.demoVendorEmail &&
        password == AppConstants.demoVendorPassword) {
      return MockCatalog.demoVendor;
    }
    return Vendor(
      id: 'vendor_${email.hashCode}',
      businessName: 'Mazonn Partner',
      ownerName: email.split('@').first,
      email: email.trim(),
      phone: '+1 415 555 0200',
      category: 'Fashion',
      address: 'Karachi, Pakistan',
      logoLabel: 'MP',
      approvalStatus: 'pending',
      registeredAt: DateTime.now(),
    );
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
    await _delay();
    return Vendor(
      id: 'vendor_${email.hashCode}',
      businessName: businessName.trim(),
      ownerName: ownerName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      category: category,
      address: address.trim(),
      logoLabel: businessName.trim().isEmpty ? 'V' : businessName.trim()[0].toUpperCase(),
      approvalStatus: 'pending',
      cnic: cnic.trim(),
      bankName: bankName.trim(),
      accountTitle: accountTitle.trim(),
      accountNumber: accountNumber.trim(),
      iban: iban.trim(),
      registeredAt: DateTime.now(),
      history: [
        VendorHistoryEntry(
          at: DateTime.now(),
          action: 'registered',
          actorName: ownerName.trim(),
          detail: 'Vendor account created and waiting for Super Admin approval.',
        ),
      ],
    );
  }

  @override
  Future<void> signOut() => _delay();

  @override
  Future<void> updateUserProfile(AppUser user) => _delay();

  @override
  Future<void> updateVendorProfile(Vendor vendor) => _delay();

  @override
  Future<AppUser?> restoreUser() async => null;

  @override
  Future<Vendor?> restoreVendor() async => null;
}
