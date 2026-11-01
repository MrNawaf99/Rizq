// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'providers/group_provider.dart';
import 'services/notification_service.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/splash_screen.dart'; // ⭐ تم استدعاء الـ Splash Screen هنا

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  // ⭐ BULLETPROOF FIX: احتواء صدام التهيئة التلقائية من نظام الأندرويد
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // التطبيق لن ينهار بعد الآن إذا كان الأندرويد قد جهز Firebase مسبقاً
    debugPrint("Firebase already initialized natively: $e");
  }

  NotificationService.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => GroupProvider(),
          ),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const Jam3iyaApp(),
      ),
    ),
  );
}

class Jam3iyaApp extends StatelessWidget {
  const Jam3iyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jam3iya',
      theme: AppTheme.lightTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      // ⭐ تعديل مسار الانطلاق ليكون SplashScreen بدلاً من AuthGate
      // نظام الـ Splash Screen سيفحص Auth داخلياً عبر FirebaseAuth.instance.currentUser
      // وينقل المستخدم للمكان الصحيح للحفاظ على نظافة الـ Flow.
      home: const SplashScreen(),
    );
  }
}
