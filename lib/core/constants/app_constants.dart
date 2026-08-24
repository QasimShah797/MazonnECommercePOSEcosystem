abstract final class AppConstants {
  static const String appName = 'Mazonn';
  static const String tagline = 'Curated living, delivered.';
  static const String currencyCode = 'USD';
  static const String defaultCity = 'San Francisco';
  static const double standardDeliveryFee = 6.50;
  static const double expressDeliveryFee = 14.90;
  static const double freeShippingThreshold = 120;
  static const Duration splashDuration = Duration(milliseconds: 2200);
  static const Duration mockNetworkDelay = Duration(milliseconds: 420);

  static const String demoUserEmail = 'sophie@mazonn.app';
  static const String demoUserPassword = 'mazonn123';
  static const String demoVendorEmail = 'atelier@mazonn.app';
  static const String demoVendorPassword = 'vendor123';

  /// Web OAuth client ID from Firebase (Authentication → Google → Web client ID).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}

abstract final class StorageKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String sessionRole = 'session_role';
  static const String sessionUser = 'session_user';
  static const String sessionVendor = 'session_vendor';
  static const String rememberMe = 'remember_me';
  static const String cart = 'cart_items';
  static const String wishlist = 'wishlist_ids';
  static const String addresses = 'user_addresses';
  static const String recentSearches = 'recent_searches';
  static const String vendorProducts = 'vendor_products';
  static const String vendorOrders = 'vendor_orders';
  static const String userOrders = 'user_orders';
}
