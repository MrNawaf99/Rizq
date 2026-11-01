// lib/screens/auth/register_form_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../navigation/main_navigation.dart';
import '../../services/notification_service.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key});

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> register() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("fillAllFields".tr())),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_username_format".tr())),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_password_length".tr())),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final email = "$username@app.com";

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final rand = Random();
      final String recoveryCode =
          "JM3Y-${rand.nextInt(9999).toString().padLeft(4, '0')}-${rand.nextInt(99).toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "name": name,
        "username": username,
        "recoveryCode": recoveryCode,
        "_p": password,
        "createdAt": FieldValue.serverTimestamp(),
      });

      NotificationService.saveFCMToken(); // Fire and forget

      if (mounted) {
        setState(() => loading = false);
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.vpn_key, color: Color(0xFF0F7B6C)),
                    SizedBox(width: 8),
                    Text("رمز الدخول السري"),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "احفظ رمز الدخول هذا خارج التطبيق.\nستحتاجه إذا نسيت بيانات تسجيل الدخول.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF6F8F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF0F7B6C)
                                  .withValues(alpha: 0.3))),
                      child: SelectableText(recoveryCode,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 2,
                              color: Color(0xFF0F7B6C))),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: recoveryCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم نسخ الرمز بنجاح")));
                    },
                    child: const Text("نسخ الرمز"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainNavigation()),
                          (route) => false);
                    },
                    child: const Text("متابعة"),
                  ),
                ],
              );
            });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = "error_generic".tr();
        if (e.code == 'email-already-in-use') {
          errorMsg = "error_email_in_use".tr();
        } else if (e.code == 'weak-password') {
          errorMsg = "error_weak_password".tr();
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
      appBar: AppBar(title: Text("createAccount".tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              enabled: !loading,
              decoration: InputDecoration(
                labelText: "yourName".tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
                onPressed: loading ? null : register,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("createAccount".tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
