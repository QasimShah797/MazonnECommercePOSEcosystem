import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/mazonn_firebase.dart';
import 'data/repositories/firebase_admin_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_notification_repository.dart';
import 'data/repositories/firebase_order_repository.dart';
import 'data/repositories/firebase_product_repository.dart';
import 'services/fcm_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await MazonnFirebase.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = FirebaseNotificationRepository();
  final fcm = FcmService();
  await fcm.initialize();
  runApp(
    MazonnApp(
      session: SessionService(prefs),
      authRepository: FirebaseAuthRepository(),
      productRepository: FirebaseProductRepository(),
      orderRepository: FirebaseOrderRepository(notifications: notifications),
      notificationRepository: notifications,
      adminRepository: FirebaseAdminRepository(),
      fcmService: fcm,
    ),
  );
}
