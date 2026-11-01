// lib/screens/auth/recovery_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation/main_navigation.dart';

class RecoveryLoginScreen extends StatefulWidget {
  const RecoveryLoginScreen({super.key});

  @override
  State<RecoveryLoginScreen> createState() => _RecoveryLoginScreenState();
}

class _RecoveryLoginScreenState extends State<RecoveryLoginScreen> {
  final usernameController = TextEditingController();
  final codeController = TextEditingController();
  bool loading = false;

  Future<void> recoveryLogin() async {
    final username = usernameController.text.trim().toLowerCase();
    final code = codeController.text.trim().toUpperCase();

    if (username.isEmpty || code.isEmpty) return;

    setState(() => loading = true);

    try {
      // 1. دخول مجهول آمن ومؤقت لتخطي حماية القراءة في Firestore (Anonymous Bypass)
      final anonCred = await FirebaseAuth.instance.signInAnonymously();

      // 2. فحص المستند باستخدام Username و Recovery Code فقط
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('recoveryCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await anonCred.user?.delete(); // تنظيف سريع
        throw Exception('بيانات غير صحيحة');
      }

      // 3. جلب كلمة المرور المخفية وإعداد الإيميل
      final realPassword = query.docs.first.data()['_p'];
      final email = "$username@app.com";

      // 4. حذف الحساب المجهول نهائياً لمنع النفايات في Firebase Auth
      await anonCred.user?.delete();

      // 5. تسجيل الدخول الفعلي بحساب المستخدم الأصلي
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: realPassword,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اسم المستخدم أو رمز الدخول غير صحيح")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("استرجاع الحساب")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "أدخل اسم المستخدم ورمز الدخول الخاص بك لاستعادة حسابك.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: usernameController,
              enabled: !loading,
              decoration: const InputDecoration(
                  labelText: "اسم المستخدم", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              enabled: !loading,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                // إزالة الـ const لوجود TextStyle
                labelText: "رمز الدخول",
                hintText: "مثال: JM3Y-84KP-X2",
                // ⭐ Soft Placeholder: رمادي فاتح جداً وغير مزعج
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                    fontSize: 14),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : recoveryLogin,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("دخول"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
