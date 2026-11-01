// lib/screens/groups/group_details/overview_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../widgets/user_name_text.dart';
import '../../../core/utils/group_intelligence.dart';
import '../../../models/group_model.dart';

class OverviewTab extends StatelessWidget {
  final Group group;

  const OverviewTab({
    super.key,
    required this.group,
  });

  Widget _basicInfoSection(BuildContext context, int membersCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.tag, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "${"code".tr()}: ${group.groupCode}",
                style: const TextStyle(
                    fontWeight: FontWeight.w600, letterSpacing: 1.2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.groupCode));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("codeCopied".tr())));
              },
            )
          ],
        ),
        const SizedBox(height: 6),
        Text("₹${group.monthlyAmount} / ${"month".tr()}"),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Text("leader".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        if (group.members.isNotEmpty)
          UserNameText(
              uid: group.members.first,
              prefix: "👑 ",
              style: const TextStyle(fontWeight: FontWeight.w600))
        else
          const Text("—", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text("members".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text("👥 $membersCount ${"members".tr()}",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text("startDate".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text("📅 ${group.startDate.month}/${group.startDate.year}",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text("endDate".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text("🏁 ${group.endDate.month}/${group.endDate.year}",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = GroupIntelligence.isCompleted(group);
    final order =
        group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;
    final membersCount = order.length;

    // 🚨 التحول إلى وضع الأرشيف (Final Report) عند الانتهاء
    if (isCompleted) {
      final receiveAmount = group.monthlyAmount * membersCount;
      return Container(
        color: const Color(0xFFF6F8F7),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
                child: Icon(Icons.verified, color: Colors.grey, size: 60)),
            const SizedBox(height: 12),
            const Center(
                child: Text("Group Completed",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey))),
            const SizedBox(height: 24),
            _basicInfoSection(context, membersCount),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.monetization_on, color: Color(0xFFD4AF37)),
                title: Text("totalReceiving".tr()),
                trailing: Text("₹$receiveAmount",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD4AF37))),
              ),
            ),
          ],
        ),
      );
    }

    if (!group.distributionStarted) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _basicInfoSection(context, group.members.length),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "waitingLeaderDistribution".tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    final total = GroupIntelligence.totalMonths(group);
    final passed = GroupIntelligence.passedMonths(
        group); // ⭐ SAFE FIX: توحيد مصدر الحساب مع الـ Progress Bar
    final progress = GroupIntelligence.progress(group);

    if (order.isEmpty) return Center(child: Text("noMembersYet".tr()));

    final currentIndex =
        GroupIntelligence.currentReceiverIndex(group, membersCount);
    if (currentIndex == -1) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _basicInfoSection(context, membersCount),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "groupNotStarted".tr(),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
          ),
        ],
      );
    }

    final nextIndex = GroupIntelligence.nextReceiverIndex(group, membersCount);
    final currentReceiver = order[currentIndex];
    final hasNextReceiver = nextIndex != -1;
    final nextReceiver = hasNextReceiver ? order[nextIndex] : "";

    final isMeCurrent = currentReceiver == group.myUserId;
    final isMeNext = hasNextReceiver && (nextReceiver == group.myUserId);

    return Container(
      color: const Color(0xFFF6F8F7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _basicInfoSection(context, membersCount),
          const SizedBox(height: 12),
          Text("currentReceiver".tr(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          if (isMeCurrent)
            Text("your_turn".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16))
          else
            UserNameText(
                uid: currentReceiver,
                prefix: "👤 ",
                suffix: "   ✅",
                style: const TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 12),
          Text("nextReceiver".tr(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          if (!hasNextReceiver)
            Text("jam3iya_completed_status".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 15))
          else if (isMeNext)
            Text("your_turn_n".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16))
          else
            UserNameText(
                uid: nextReceiver,
                prefix: "👤 ",
                style: const TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 12),
          Text("yourTurn".tr(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final myIndex = order.indexOf(group.myUserId);
              if (myIndex == -1) return const SizedBox();

              int monthsUntilTurn;
              if (currentIndex <= myIndex) {
                monthsUntilTurn = myIndex - currentIndex;
              } else {
                monthsUntilTurn = order.length - (currentIndex - myIndex);
              }

              final myReceiveDate = DateTime(group.startDate.year,
                  group.startDate.month + currentIndex + monthsUntilTurn);
              final formattedMonth = DateFormat.yMMM(context.locale.toString())
                  .format(myReceiveDate);

              return Text(
                "⭐ $formattedMonth",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              );
            },
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0F7B6C)),
          ),
          const SizedBox(height: 8),
          Text("$passed / $total ${"months".tr()}"),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("${"status".tr()}: "),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.isClosed
                      ? const Color(0xFFD32F2F).withValues(alpha: 0.15)
                      : const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  group.isClosed ? "closed".tr() : "active".tr(),
                  style: TextStyle(
                    color: group.isClosed
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
