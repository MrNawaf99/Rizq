// lib/screens/groups/join_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final codeController = TextEditingController();
  bool loading = false;

  Future<void> join() async {
    final code = codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<GroupProvider>();

    try {
      await provider.joinGroup(code);
      // ⭐ FIX: Add missing mounted check before navigation
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text("waiting_for_approval".tr())),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();
      String message;

      if (error.contains("closed")) {
        message = "groupClosedJoin".tr();
      } else if (error.contains("already_member")) {
        message = "error_already_member".tr();
      } else if (error.contains("already_requested")) {
        message = "error_already_requested".tr();
      } else if (error.contains("not_found")) {
        message = "groupNotFound".tr();
      } else {
        message = "invalidCode".tr();
      }

      messenger.showSnackBar(SnackBar(content: Text(message)));
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("joinGroup".tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: codeController,
              enabled: !loading,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "groupCode".tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "exampleCode".tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : join,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("joinGroup".tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
