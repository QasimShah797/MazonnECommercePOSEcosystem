abstract final class AppConstants {
  static const String appName = 'Mazonn';
  static const String tagline = 'Curated living, delivered.';
  static const String currencyCode = 'PKR';
  static const String defaultCity = 'Karachi';
  static const String defaultCountry = 'Pakistan';
  static const double standardDeliveryFee = 250;
  static const double expressDeliveryFee = 450;
  static const double freeShippingThreshold = 5000;
  static const List<String> pakistanProvinces = [
    'Sindh',
    'Punjab',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu and Kashmir',
  ];
  static const List<String> pakistanCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Peshawar',
    'Quetta',
    'Multan',
    'Hyderabad',
    'Sialkot',
    'Gujranwala',
    'Bahawalpur',
  ];
  static const Duration splashDuration = Duration(milliseconds: 2200);
  static const Duration mockNetworkDelay = Duration(milliseconds: 420);

  static const String demoUserEmail = 'sophie@mazonn.app';
  static const String demoUserPassword = 'mazonn123';
  static const String demoVendorEmail = 'atelier@mazonn.app';
  static const String demoVendorPassword = 'vendor123';
  static const String demoAdminEmail = 'admin@mazonn.app';
  static const String demoAdminPassword = 'admin123';

  /// Web OAuth client ID from Firebase (client_type 3). Required for Google Sign-In on Android.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '1034972929409-tu22kpm5b0lsipo7sfrh65go6ub2qsna.apps.googleusercontent.com',
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
  static const String searchSynonyms = 'search_synonyms';
}
