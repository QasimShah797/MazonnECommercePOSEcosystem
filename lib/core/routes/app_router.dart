import 'package:go_router/go_router.dart';

import '../../models/address.dart';
import '../../models/product.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../shared/widgets/app_shells.dart';
import '../../user/screens/auth_screens.dart';
import '../../user/screens/cart_screen.dart';
import '../../user/screens/categories_screen.dart';
import '../../user/screens/checkout_screen.dart';
import '../../user/screens/home_screen.dart';
import '../../user/screens/onboarding_screen.dart';
import '../../user/screens/orders_screen.dart';
import '../../user/screens/product_details_screen.dart';
import '../../user/screens/profile_screens.dart';
import '../../user/screens/search_screen.dart';
import '../../user/screens/splash_screen.dart';
import '../../vendor/screens/vendor_analytics_profile.dart';
import '../../vendor/screens/vendor_auth_screens.dart';
import '../../vendor/screens/vendor_commerce_screens.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter create(AuthController auth) {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final public = {
          RouteNames.splash,
          RouteNames.onboarding,
          RouteNames.login,
          RouteNames.signup,
          RouteNames.forgotPassword,
          RouteNames.vendorLogin,
          RouteNames.vendorRegister,
        };
        if (loc == RouteNames.splash) return null;
        if (!auth.onboardingComplete && loc != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }
        if (!auth.isAuthenticated && !public.contains(loc)) {
          return loc.startsWith('/studio') || loc.startsWith('/vendor')
              ? RouteNames.vendorLogin
              : RouteNames.login;
        }
        if (auth.isUser && (loc == RouteNames.login || loc == RouteNames.signup || loc == RouteNames.onboarding)) {
          return RouteNames.userHome;
        }
        if (auth.isVendor && (loc == RouteNames.vendorLogin || loc == RouteNames.vendorRegister)) {
          return RouteNames.vendorDashboard;
        }
        if (auth.isUser && loc.startsWith('/studio')) return RouteNames.userHome;
        if (auth.isVendor && loc.startsWith('/shop')) return RouteNames.vendorDashboard;
        return null;
      },
      routes: [
        GoRoute(path: RouteNames.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: RouteNames.onboarding, builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: RouteNames.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: RouteNames.signup, builder: (_, _) => const SignUpScreen()),
        GoRoute(path: RouteNames.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
        GoRoute(path: RouteNames.vendorLogin, builder: (_, _) => const VendorLoginScreen()),
        GoRoute(path: RouteNames.vendorRegister, builder: (_, _) => const VendorRegisterScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => UserShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.userHome, builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.userCategories, builder: (_, _) => const CategoriesScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.userCart, builder: (_, _) => const CartScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.userOrders, builder: (_, _) => const OrdersScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.userProfile, builder: (_, _) => const ProfileScreen())]),
          ],
        ),
        GoRoute(path: '/shop/search', builder: (_, _) => const SearchScreen()),
        GoRoute(
          path: '/shop/category/:id',
          builder: (_, state) => ProductListingScreen(categoryId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/shop/product/:id',
          builder: (_, state) => ProductDetailsScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/shop/wishlist', builder: (_, _) => const WishlistScreen()),
        GoRoute(path: '/shop/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(
          path: '/shop/order-success',
          builder: (_, state) => OrderSuccessScreen(orderId: state.extra as String?),
        ),
        GoRoute(
          path: '/shop/orders/:id',
          builder: (_, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/shop/orders/:id/track',
          builder: (_, state) => OrderTrackingScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/shop/profile/edit', builder: (_, _) => const EditProfileScreen()),
        GoRoute(path: '/shop/profile/addresses', builder: (_, _) => const AddressesScreen()),
        GoRoute(
          path: '/shop/profile/addresses/form',
          builder: (_, state) => AddressFormScreen(existing: state.extra as Address?),
        ),
        GoRoute(path: '/shop/profile/payments', builder: (_, _) => const PaymentMethodsScreen()),
        GoRoute(path: '/shop/notifications', builder: (_, _) => const NotificationsScreen()),
        GoRoute(path: '/shop/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/shop/help', builder: (_, _) => const HelpScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => VendorShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.vendorDashboard, builder: (_, _) => const VendorDashboardScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.vendorProducts, builder: (_, _) => const VendorProductsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.vendorOrders, builder: (_, _) => const VendorOrdersScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.vendorAnalytics, builder: (_, _) => const VendorAnalyticsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: RouteNames.vendorProfile, builder: (_, _) => const VendorProfileScreen())]),
          ],
        ),
        GoRoute(
          path: '/studio/products/form',
          builder: (_, state) => VendorProductFormScreen(existing: state.extra as Product?),
        ),
        GoRoute(
          path: '/studio/orders/:id',
          builder: (_, state) => VendorOrderDetailsScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/studio/profile/edit', builder: (_, _) => const VendorEditProfileScreen()),
        GoRoute(path: '/studio/settings', builder: (_, _) => const VendorSettingsScreen()),
      ],
    );
  }
}
