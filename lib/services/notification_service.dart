// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ⭐ FIX: تأمين التهيئة في الباكجراوند لمنع الـ Duplicate App Crash
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _updateTokenInFirestore(newToken);
    });

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'jam3iya_channel',
      'Jam3iya Notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification != null) {
        try {
          await _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'jam3iya_channel',
                'Jam3iya Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        } catch (e) {
          debugPrint("Notification UI Error: $e");
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .get();

          final count = snapshot.docs.length;
          if (await AppBadgePlus.isSupported()) {
            AppBadgePlus.updateBadge(count);
          }
        } catch (e) {
          debugPrint("Failed to update badge: $e");
        }
      }
    });
  }

  static Future<void> saveFCMToken() async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "fcmToken": token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to save FCM token to Firestore: $e");
    }
  }

  static Future<void> requestPermissionAndSaveToken() async {
    await saveFCMToken();
  }
}
