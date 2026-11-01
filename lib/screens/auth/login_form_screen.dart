// lib/screens/auth/login_form_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jam3iya_app/screens/auth/recovery_login_screen.dart';
import '../navigation/main_navigation.dart';
import 'register_form_screen.dart';
import '../../services/notification_service.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("enterUsernamePassword".tr())),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final email = "$username@app.com";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      NotificationService.saveFCMToken(); // Fire and forget

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigation(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = "error_generic".tr();
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-email') {
          errorMsg = "error_user_not_found".tr();
        } else if (e.code == 'wrong-password') {
          errorMsg = "error_wrong_password".tr();
        } else if (e.code == 'network-request-failed') {
          errorMsg = "error_network".tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("error_generic".tr())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Ensure translations update instantly
    return Scaffold(
      appBar: AppBar(title: Text("login".tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              enabled: !loading,
              decoration: InputDecoration(
                labelText: "username".tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              enabled: !loading,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "password".tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("login".tr()),
              ),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterFormScreen()));
                    },
              child: Text("createAccount".tr()),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RecoveryLoginScreen()));
                    },
              child: const Text("نسيت بياناتك؟ استخدم رمز الدخول",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
