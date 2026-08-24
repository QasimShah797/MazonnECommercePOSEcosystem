abstract final class RouteNames {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static const String userHome = '/shop';
  static const String userCategories = '/shop/categories';
  static const String userCart = '/shop/cart';
  static const String userOrders = '/shop/orders';
  static const String userProfile = '/shop/profile';
  static const String search = '/shop/search';
  static const String categoryProducts = '/shop/category/:id';
  static const String productDetails = '/shop/product/:id';
  static const String wishlist = '/shop/wishlist';
  static const String checkout = '/shop/checkout';
  static const String orderSuccess = '/shop/order-success';
  static const String orderDetails = '/shop/orders/:id';
  static const String orderTracking = '/shop/orders/:id/track';
  static const String editProfile = '/shop/profile/edit';
  static const String addresses = '/shop/profile/addresses';
  static const String addressForm = '/shop/profile/addresses/form';
  static const String paymentMethods = '/shop/profile/payments';
  static const String notifications = '/shop/notifications';
  static const String settings = '/shop/settings';
  static const String help = '/shop/help';

  static const String vendorLogin = '/vendor/login';
  static const String vendorRegister = '/vendor/register';
  static const String vendorDashboard = '/studio';
  static const String vendorProducts = '/studio/products';
  static const String vendorProductForm = '/studio/products/form';
  static const String vendorOrders = '/studio/orders';
  static const String vendorOrderDetails = '/studio/orders/:id';
  static const String vendorAnalytics = '/studio/analytics';
  static const String vendorProfile = '/studio/profile';
  static const String vendorEditProfile = '/studio/profile/edit';
  static const String vendorSettings = '/studio/settings';
}
