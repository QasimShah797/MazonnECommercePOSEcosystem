import '../../models/user.dart';
import '../../models/vendor.dart';

abstract class AuthRepository {
  Future<AppUser> loginUser({required String email, required String password});
  Future<AppUser> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });
  Future<AppUser> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<Vendor> loginVendor({required String email, required String password});
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
  });
  Future<void> signOut();
  Future<void> updateUserProfile(AppUser user);
  Future<void> updateVendorProfile(Vendor vendor);
  Future<AppUser?> restoreUser();
  Future<Vendor?> restoreVendor();
}
