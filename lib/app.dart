import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/controllers/admin_controller.dart';
import 'core/routes/app_router.dart';
import 'core/theme/mazonn_theme.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_product_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/product_repository.dart';
import 'services/fcm_service.dart';
import 'services/session_service.dart';
import 'shared/controllers/auth_controller.dart';
import 'user/controllers/address_controller.dart';
import 'user/controllers/cart_controller.dart';
import 'user/controllers/catalog_controller.dart';
import 'user/controllers/notification_controller.dart';
import 'user/controllers/order_controller.dart';
import 'user/controllers/wishlist_controller.dart';
import 'vendor/controllers/vendor_studio_controller.dart';

class MazonnApp extends StatefulWidget {
  const MazonnApp({
    super.key,
    required this.session,
    this.authRepository,
    this.productRepository,
    this.orderRepository,
    this.notificationRepository,
    this.adminRepository,
    this.fcmService,
  });

  final SessionService session;
  final AuthRepository? authRepository;
  final ProductRepository? productRepository;
  final OrderRepository? orderRepository;
  final NotificationRepository? notificationRepository;
  final AdminRepository? adminRepository;
  final FcmService? fcmService;

  @override
  State<MazonnApp> createState() => _MazonnAppState();
}

class _MazonnAppState extends State<MazonnApp> {
  late final AuthController _auth;
  late final CatalogController _catalog;
  late final CartController _cart;
  late final WishlistController _wishlist;
  late final AddressController _addresses;
  late final OrderController _orders;
  late final VendorStudioController _vendor;
  late final NotificationController _notifications;
  late final AdminController _admin;
  late final router = AppRouter.create(_auth);

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    final products = widget.productRepository ?? MockProductRepository();
    final notifications = widget.notificationRepository ?? MockNotificationRepository(session);
    final orders = widget.orderRepository ?? MockOrderRepository(session, notifications: notifications);
    _auth = AuthController(
      authRepository: widget.authRepository ?? MockAuthRepository(),
      session: session,
    );
    _catalog = CatalogController(repository: products, session: session);
    _cart = CartController(session);
    _wishlist = WishlistController(session);
    _addresses = AddressController(session);
    _orders = OrderController(orders);
    _vendor = VendorStudioController(orders: orders, products: products, session: session);
    _notifications = NotificationController(notifications);
    _admin = AdminController(widget.adminRepository ?? MockAdminRepository());
    _catalog.load();
    _orders.load();
    _vendor.load();
    _admin.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.restoreSession().then((_) {
        final id = _auth.recipientId;
        if (id.isNotEmpty) {
          _notifications.bind(id);
          widget.fcmService?.register(userId: id, role: _auth.role.name);
        }
      });
    });
    _auth.addListener(_onAuth);
    widget.fcmService?.onNotificationTap = (orderId) {
      if (_auth.isVendor) {
        router.go('/studio/orders/$orderId');
      } else if (_auth.isUser) {
        router.go('/shop/orders/$orderId');
      }
    };
  }

  String? _boundAuthId;

  void _onAuth() {
    final id = _auth.recipientId;
    if (id == _boundAuthId) return;
    _boundAuthId = id;
    if (_auth.isAuthenticated && id.isNotEmpty) {
      _notifications.bind(id);
      widget.fcmService?.register(userId: id, role: _auth.role.name);
      if (_auth.isVendor) _vendor.load();
      if (_auth.isUser) _orders.load();
      if (_auth.isAdmin) _admin.load();
    }
    if (!_auth.isAuthenticated) {
      widget.fcmService?.unregister(id);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _catalog),
        ChangeNotifierProvider.value(value: _cart),
        ChangeNotifierProvider.value(value: _wishlist),
        ChangeNotifierProvider.value(value: _addresses),
        ChangeNotifierProvider.value(value: _orders),
        ChangeNotifierProvider.value(value: _vendor),
        ChangeNotifierProvider.value(value: _notifications),
        ChangeNotifierProvider.value(value: _admin),
      ],
      child: MaterialApp.router(
        title: 'Mazonn',
        debugShowCheckedModeBanner: false,
        theme: MazonnTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
