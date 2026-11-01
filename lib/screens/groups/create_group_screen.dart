// lib/screens/groups/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/group_model.dart';
import '../../providers/group_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final amountController = TextEditingController();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 180));

  final messageController = TextEditingController();
  TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0);

  bool isLoading = false;

  int get totalMonths {
    return (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month) +
        1;
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Ensure translations update instantly
    final provider = context.read<GroupProvider>();
    final currentUid = provider.currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text("createGroup".tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                enabled: !isLoading,
                decoration: InputDecoration(labelText: "groupName".tr()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "enterName".tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "monthlyAmount".tr()),
                validator: (v) {
                  if (v == null || v.isEmpty) return "enterAmount".tr();
                  final parsed = int.tryParse(v);
                  if (parsed == null) return "invalidAmount".tr();
                  if (parsed <= 0) return "error_invalid_amount_positive".tr();
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                title: Text("startMonth".tr()),
                subtitle: Text("${startDate.month}/${startDate.year}"),
                trailing: const Icon(Icons.edit),
                onTap: isLoading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
              ),
              ListTile(
                title: Text("endMonth".tr()),
                subtitle: Text("${endDate.month}/${endDate.year}"),
                trailing: const Icon(Icons.edit),
                onTap: isLoading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime(2045),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
              ),
              const SizedBox(height: 8),
              Text(
                "${"totalDuration".tr()}: $totalMonths ${"months".tr()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: messageController,
                enabled: !isLoading,
                decoration:
                    InputDecoration(labelText: "monthlyMessageOptional".tr()),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("notificationTime".tr()),
                subtitle: Text(notificationTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: isLoading
                    ? null
                    : () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: notificationTime,
                        );
                        if (picked != null) {
                          setState(() => notificationTime = picked);
                        }
                      },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          if (totalMonths <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("error_date_invalid".tr())),
                            );
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isLoading = true);

                          try {
                            await provider.addGroup(
                              Group(
                                id: '',
                                name: nameController.text.trim(),
                                monthlyAmount: int.parse(amountController.text),
                                receiverName: "",
                                receiveDate: startDate,
                                startDate: startDate,
                                endDate: endDate,
                                isCompleted: false,
                                members: [currentUid],
                                pendingMembers: [],
                                receiverOrder: [currentUid],
                                myUserId: currentUid,
                                roles: {currentUid: GroupRole.leader},
                                payments: {},
                                paidMonths: [],
                                monthlyMessage: messageController.text.trim(),
                                notificationHour: notificationTime.hour,
                                notificationMinute: notificationTime.minute,
                              ),
                            );
                            if (mounted) {
                              navigator.pop();
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text("error_generic".tr())),
                              );
                            }
                          } finally {
                            // ⭐ STRICT FIX: Guarantees loading ALWAYS stops if it didn't navigate away
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text("createGroupButton".tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
