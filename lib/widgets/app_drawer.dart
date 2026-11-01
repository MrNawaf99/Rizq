// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_name_text.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/auth/welcome_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onSelectPage;

  const AppDrawer({
    super.key,
    required this.onSelectPage,
  });

  @override
  Widget build(BuildContext context) {
    context.locale; // Ensure drawer translates instantly

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 32),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      return const SizedBox();
                    }

                    return UserNameText(
                      uid: user.uid,
                      prefix: "@",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text("home".tr()),
            onTap: () {
              Navigator.pop(context);
              onSelectPage(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text("settings".tr()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text("about".tr()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text("logout".tr()),
            onTap: () async {
              // FIX: Capture navigator strictly before context is popped to ensure proper routing
              final nav = Navigator.of(context);
              nav.pop();

              await FirebaseAuth.instance.signOut();

              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
