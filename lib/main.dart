import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/mazonn_firebase.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_order_repository.dart';
import 'data/repositories/firebase_product_repository.dart';
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
  runApp(
    MazonnApp(
      session: SessionService(prefs),
      authRepository: FirebaseAuthRepository(),
      productRepository: FirebaseProductRepository(),
      orderRepository: FirebaseOrderRepository(),
    ),
  );
}
