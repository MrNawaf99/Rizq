// lib/screens/groups/group_details/members_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/user_name_text.dart';
import '../../../core/utils/group_intelligence.dart';

class MembersTab extends StatelessWidget {
  final Group group;

  const MembersTab({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8F7),
      child: Column(
        children: [
          if (group.pendingMembers.isNotEmpty && group.canManage)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text(
                  "pending_requests"
                      .tr(args: [group.pendingMembers.length.toString()]),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.person_add),
                children: group.pendingMembers.map((uid) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: UserNameText(uid: uid)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => context
                                  .read<GroupProvider>()
                                  .rejectMember(group, uid),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => context
                                  .read<GroupProvider>()
                                  .approveMember(group, uid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final uid = group.members[index];
                final isMe = uid == group.myUserId;
                final targetRole = group.roles[uid] ?? GroupRole.member;
                final myRole = group.myRole;

                String roleText = "member".tr();
                if (targetRole == GroupRole.leader) {
                  roleText = "leader".tr();
                } else if (targetRole == GroupRole.assistant) {
                  roleText = "assistant".tr();
                }

                // ⭐ ضبط صارم لصلاحيات واجهة الإدارة وتجميدها في الأرشيف
                final isCompleted = GroupIntelligence.isCompleted(group);
                bool canShowMenu = false;
                List<PopupMenuEntry<String>> menuItems = [];

                // إخفاء خيارات الإدارة تماماً إذا انتهت الجمعية
                if (!isMe && !isCompleted) {
                  if (myRole == GroupRole.leader) {
                    canShowMenu = true;
                    if (targetRole != GroupRole.assistant) {
                      menuItems.add(PopupMenuItem(
                          value: "assistant",
                          child: Text("make_assistant".tr())));
                    }
                    if (targetRole == GroupRole.assistant) {
                      menuItems.add(PopupMenuItem(
                          value: "member", child: Text("make_member".tr())));
                    }
                    menuItems.add(PopupMenuItem(
                        value: "remove", child: Text("remove_member".tr())));
                  } else if (myRole == GroupRole.assistant) {
                    // المساعد يستطيع الإدارة على الأعضاء فقط (يُمنع عند القائد والمساعدين الآخرين)
                    if (targetRole == GroupRole.member) {
                      canShowMenu = true;
                      menuItems.add(PopupMenuItem(
                          value: "remove", child: Text("remove_member".tr())));
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F7B6C)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person,
                                color: Color(0xFF0F7B6C)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: UserNameText(uid: uid)),
                                    if (isMe)
                                      Text(
                                        "you_label".tr(),
                                        style: const TextStyle(
                                            color: Color(0xFF6B6B6B)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(roleText,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B6B6B))),
                              ],
                            ),
                          ),
                          if (targetRole == GroupRole.leader)
                            const Icon(Icons.emoji_events,
                                color: Color(0xFFD4AF37)),
                          if (canShowMenu && menuItems.isNotEmpty)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                final provider = context.read<GroupProvider>();
                                if (value == "assistant") {
                                  provider.makeAssistant(
                                      groupId: group.id, memberId: uid);
                                } else if (value == "member") {
                                  provider.makeMember(
                                      groupId: group.id, memberId: uid);
                                } else if (value == "remove") {
                                  // السجل المالي السابق لا يمنع الحذف الإداري
                                  provider.removeMember(
                                      groupId: group.id, memberId: uid);
                                }
                              },
                              itemBuilder: (context) => menuItems,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
