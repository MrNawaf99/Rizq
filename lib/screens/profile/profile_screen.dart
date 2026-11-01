// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/group_provider.dart';
import '../groups/group_details/group_details_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // ⭐ Dependency for language instant updates
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final provider = context.watch<GroupProvider>();
    final active = provider.active;
    final completed = provider.completed;

    if (uid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        const Center(child: CircleAvatar(radius: 40)),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile."));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data["name"] ?? "user".tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _showEditNameDialog(context, uid, data["name"] ?? ""),
                      child: const Icon(Icons.edit_rounded,
                          size: 20, color: Color(0xFF0F7B6C)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("@${data["username"] ?? ''}",
                    style: const TextStyle(color: Colors.grey)),

                // ⭐ قسم رمز الدخول بتصميم احترافي متكامل
                if (data["recoveryCode"] != null) ...[
                  const SizedBox(height: 32), // مسافة مريحة للعين
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_rounded,
                                color: Color(0xFF0F7B6C), size: 20),
                            SizedBox(width: 8),
                            Text("رمز الدخول",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text("هذا رمز الدخول الخاص بك",
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF0F7B6C)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data["recoveryCode"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    fontSize: 18,
                                    color: Color(0xFF0F7B6C)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: data["recoveryCode"]));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("تم نسخ رمز الدخول")));
                                },
                                child: const Icon(Icons.copy_rounded,
                                    color: Color(0xFF0F7B6C), size: 22),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          "groupsHistory".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...active.map((g) => Card(
              child: ListTile(
                leading:
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                title: Text(g.name),
                subtitle: Text(
                  "${DateFormat.yMMM(context.locale.toString()).format(g.startDate)} → "
                  "${DateFormat.yMMM(context.locale.toString()).format(g.endDate)}",
                ),
                trailing: Text(
                  "monthly_amount".tr(args: [g.monthlyAmount.toString()]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(group: g),
                    ),
                  );
                },
              ),
            )),
        ...completed.map((g) => Card(
              child: ListTile(
                leading: const Icon(Icons.circle, color: Colors.grey, size: 12),
                title: Text(g.name),
                subtitle: Text(
                  "${DateFormat.yMMM(context.locale.toString()).format(g.startDate)} → "
                  "${DateFormat.yMMM(context.locale.toString()).format(g.endDate)}",
                ),
                trailing: Text(
                  "monthly_amount".tr(args: [g.monthlyAmount.toString()]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(group: g),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }

  void _showEditNameDialog(
      BuildContext context, String uid, String currentName) {
    final controller = TextEditingController(text: currentName);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("editName".tr()),
              content: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLength: 25,
                decoration: InputDecoration(
                  hintText: "yourName".tr(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text("cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = controller.text.trim();
                          if (newName.length < 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("error_name_length".tr())),
                            );
                            return;
                          }

                          setState(() => isLoading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final groupProvider = context.read<GroupProvider>();

                          try {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(uid)
                                .update({"name": newName});

                            // تحديث الاسم فوراً في الذاكرة المؤقتة ليعكس التغيير في كل مكان
                            groupProvider.updateCachedUserName(uid, newName);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text("nameUpdated".tr())),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text("error_generic".tr())),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text("saveChanges".tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
