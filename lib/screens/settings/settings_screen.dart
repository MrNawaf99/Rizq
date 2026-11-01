// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../about/about_screen.dart';
import '../auth/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // ⭐ Dependency for language instant updates
    context.locale;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("settings".tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 24,
                child: Icon(Icons.person),
              ),
              title: Text(
                user?.email ?? "user".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("loggedInAccount".tr()),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "general".tr(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text("language".tr()),
                  trailing: TextButton(
                    onPressed: () async {
                      if (context.locale.languageCode == 'ar') {
                        await context.setLocale(const Locale('en'));
                      } else {
                        await context.setLocale(const Locale('ar'));
                      }
                      if (mounted) setState(() {});
                    },
                    child: Text(
                      context.locale.languageCode == 'ar'
                          ? "english".tr()
                          : "arabic".tr(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text("aboutApp".tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text("appVersion".tr()),
                  subtitle: Text("app_version_number".tr(args: ["1.0.0"])),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Card(
            color: Colors.red.withValues(alpha: 0.05),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                "logout".tr(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),

          const SizedBox(height: 50), // مساحة تفصل الإعدادات عن الفوتر

          // ⭐ DEVELOPER CREDIT (Settings Footer)
          const Text(
            "Developed by Nawaf & Abdulrazzaq",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey, // أو Colors.grey.shade500
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24), // مساحة أمان أخيرة
        ],
      ),
    );
  }
}
