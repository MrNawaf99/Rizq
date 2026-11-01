// lib/screens/groups/group_details/manage_tab.dart
import 'package:flutter/material.dart';
import 'package:jam3iya_app/core/config/feature_flags.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/user_name_text.dart';
import '../../../providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTab extends StatefulWidget {
  final Group group;
  const ManageTab({super.key, required this.group});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  late DateTime startDate;
  late DateTime endDate;
  late List<String> receiverOrder;
  late TextEditingController messageController;
  late TimeOfDay notificationTime;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    startDate = widget.group.startDate;
    endDate = widget.group.endDate;
    receiverOrder = widget.group.receiverOrder.isNotEmpty
        ? List<String>.from(widget.group.receiverOrder)
        : List<String>.from(widget.group.members);

    for (final m in widget.group.members) {
      if (!receiverOrder.contains(m)) receiverOrder.add(m);
    }

    messageController =
        TextEditingController(text: widget.group.monthlyMessage);
    notificationTime = TimeOfDay(
        hour: widget.group.notificationHour,
        minute: widget.group.notificationMinute);
  }

  void _confirmDelete(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final rootNav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("deleteGroup".tr()),
            content: Text("deleteGroupWarning".tr()),
            actions: [
              TextButton(
                onPressed:
                    isDeleting ? null : () => Navigator.pop(dialogContext),
                child: Text("cancel".tr()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await groupProvider.deleteGroup(widget.group);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            rootNav.popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isDeleting = false);
                          }
                          if (mounted) {
                            messenger.showSnackBar(
                                SnackBar(content: Text("error_generic".tr())));
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text("delete".tr()),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group.isClosed) {
      return Scaffold(
        appBar: AppBar(title: Text("manageGroup".tr())),
        body: Center(
          child: Text(
            "groupClosedEditingDisabled".tr(),
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("manageGroup".tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("editStartDate".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text("${startDate.month}/${startDate.year}"),
            trailing: const Icon(Icons.edit),
            onTap: isSaving
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
          ),
          const SizedBox(height: 20),
          Text("editEndDate".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text("${endDate.month}/${endDate.year}"),
            trailing: const Icon(Icons.edit),
            onTap: isSaving
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2040),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
          ),
          const SizedBox(height: 30),
          Text("receiverOrder".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed:
                isSaving ? null : () => setState(() => receiverOrder.shuffle()),
            child: Text("randomOrder".tr()),
          ),

          // ⭐ تحسين UX إعادة الترتيب: يمكن سحب الصف بأكمله
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: receiverOrder.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = receiverOrder.removeAt(oldIndex);
                receiverOrder.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final uid = receiverOrder[index];
              return ReorderableDragStartListener(
                key: ValueKey(uid),
                index: index,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: UserNameText(uid: uid),
                    leading:
                        const Icon(Icons.drag_indicator, color: Colors.grey),
                  ),
                ),
              );
            },
          ),

          if (!widget.group.distributionStarted)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isSaving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      final groupProvider = context.read<GroupProvider>();

                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("startDistribution".tr()),
                          content: Text("startDistributionConfirm".tr()),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("cancel".tr())),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("confirm".tr())),
                          ],
                        ),
                      );
                      if (confirm != true || !mounted) return;

                      setState(() => isSaving = true);
                      try {
                        await groupProvider.startDistribution(widget.group);
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(
                              content: Text("distributionStarted".tr())));
                          nav.pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                              SnackBar(content: Text("error_generic".tr())));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
              child: Text("startDistribution".tr()),
            ),
          // ⭐ إعدادات الشات (Mute Control) مع الترجمة والمزامنة اللحظية
          if (widget.group.myRole == GroupRole.leader)
            Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                // جلب النسخة المحدثة لحظياً من الجروب
                final currentGroup =
                    groupProvider.getGroup(widget.group.id) ?? widget.group;

                // ⭐ التغليف الصحيح بـ Column
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text("lock_chat_title".tr()),
                      subtitle: Text("lock_chat_subtitle".tr()),
                      value: currentGroup.chatMode == 'leaders_only',
                      activeThumbColor: const Color(0xFF0F7B6C),
                      onChanged: (bool value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final chatProvider = context.read<ChatProvider>();
                        final newMode = value ? 'leaders_only' : 'all_members';
                        await chatProvider.updateChatMode(widget.group.id, newMode);
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(
                              content: Text("chat_mode_updated".tr())));
                        }
                      },
                    ),
                    // ⭐ مفتاح تحكم القائد في صور الأعضاء (مجمد مؤقتاً)
                    if (FeatureFlags.imageFeaturesEnabled)
                      SwitchListTile(
                        title: Text("allow_member_images".tr()),
                        subtitle: Text("allow_member_images_desc".tr()),
                        value: currentGroup.allowMemberImageMessages,
                        activeThumbColor: const Color(0xFF0F7B6C),
                        onChanged: (bool value) async {
                          await FirebaseFirestore.instance
                              .collection('groups')
                              .doc(widget.group.id)
                              .update({
                            'allowMemberImageMessages': value,
                          });
                        },
                      ),
                  ],
                ); // ⭐ إغلاق الـ Column
              },
            ),
          const SizedBox(height: 20),
          TextFormField(
            controller: messageController,
            enabled: !isSaving,
            decoration:
                InputDecoration(labelText: "monthlyMessageOptional".tr()),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text("notificationTime".tr()),
            subtitle: Text(notificationTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: isSaving
                ? null
                : () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: notificationTime);
                    if (picked != null) {
                      setState(() => notificationTime = picked);
                    }
                  },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final groupProvider = context.read<GroupProvider>();
                    setState(() => isSaving = true);
                    try {
                      await groupProvider.updateGroupSettings(
                            widget.group,
                            startDate,
                            endDate,
                            receiverOrder,
                            messageController.text.trim(),
                            notificationTime.hour,
                            notificationTime.minute,
                          );
                      if (mounted) {
                        messenger.showSnackBar(
                            SnackBar(content: Text("settingsUpdated".tr())));
                      }
                    } catch (_) {
                      if (mounted) {
                        messenger.showSnackBar(
                            SnackBar(content: Text("error_generic".tr())));
                      }
                    } finally {
                      if (mounted) {
                        setState(() => isSaving = false);
                      }
                    }
                  },
            child: isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text("saveChanges".tr()),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: isSaving ? null : () => _confirmDelete(context),
            child: Text("deleteGroup".tr()),
          ),
        ],
      ),
    );
  }
}
