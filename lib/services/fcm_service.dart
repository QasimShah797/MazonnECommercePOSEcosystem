import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/firebase/mazonn_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> mazonnFirebaseBackgroundHandler(RemoteMessage message) async {
  // Background isolate — keep this handler lightweight.
}

class FcmService {
  FcmService();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  String? _token;
  void Function(String orderId)? onNotificationTap;

  Future<void> initialize() async {
    if (!MazonnFirebase.isReady || kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(mazonnFirebaseBackgroundHandler);
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: DarwinInitializationSettings()),
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        if (orderId != null && orderId.isNotEmpty) onNotificationTap?.call(orderId);
      },
    );
    const channel = AndroidNotificationChannel(
      'mazonn_orders',
      'Mazonn orders',
      description: 'New orders and status updates',
      importance: Importance.high,
      playSound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final orderId = message.data['orderId'];
      if (orderId != null && orderId.isNotEmpty) onNotificationTap?.call(orderId);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_persistToken);
  }

  Future<void> register({required String userId, required String role}) async {
    if (!MazonnFirebase.isReady || userId.isEmpty) return;
    try {
      _token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return;
    }
    if (_token == null) return;
    try {
      await _persistToken(_token!, userId: userId, role: role);
    } catch (_) {}
  }

  Future<void> unregister(String userId) async {
    if (!MazonnFirebase.isReady || _token == null) return;
    try {
      await FirebaseFirestore.instance.collection('deviceTokens').doc(_token).delete();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _token = null;
  }

  Future<void> _persistToken(String token, {String? userId, String? role}) async {
    _token = token;
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('deviceTokens').doc(token).set({
      'token': token,
      'userId': uid,
      'role': role ?? 'user',
      'platform': defaultTargetPlatform.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      id: notification.hashCode,
      title: notification.title ?? 'Mazonn',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mazonn_orders',
          'Mazonn orders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      ),
      payload: message.data['orderId'],
    );
  }
}
