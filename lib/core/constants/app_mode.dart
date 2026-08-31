enum AppRole { guest, user, vendor, admin }

extension AppRoleX on AppRole {
  String get firestoreValue => name;

  static AppRole fromName(String? name) => AppRole.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppRole.guest,
      );
}
