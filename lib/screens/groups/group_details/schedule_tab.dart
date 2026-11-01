// lib/screens/groups/group_details/schedule_tab.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/group_model.dart';
import '../../../widgets/user_name_text.dart';

class ScheduleTab extends StatelessWidget {
  final Group group;

  const ScheduleTab({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final order =
        group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;

    if (!group.distributionStarted) {
      return Center(
        child: Text(
          "waitingLeader".tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (order.isEmpty) {
      return Center(child: Text("noMembers".tr()));
    }

    // ⭐ SAFE FIX: بناء الجدول الأساسي بناءً على الأعضاء الحقيقيين فقط
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: order.length,
      itemBuilder: (_, i) {
        // استخراج أول شهر استلام كإشارة لبداية دور العضو
        final dt = DateTime(group.startDate.year, group.startDate.month + i);
        final monthLabel =
            DateFormat.yMMM(context.locale.toString()).format(dt);

        final receiverUid = order[i];

        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final thisMonth = DateTime(dt.year, dt.month);

        final isPast = thisMonth.isBefore(currentMonth);
        final isCurrent = thisMonth.year == currentMonth.year &&
            thisMonth.month == currentMonth.month;
        final isMe = receiverUid == group.myUserId;

        return ListTile(
          leading: Icon(
            isPast
                ? Icons.check_circle
                : isCurrent
                    ? Icons.radio_button_checked
                    : Icons.circle_outlined,
            color: isPast
                ? Colors.grey
                : isCurrent
                    ? Colors.green
                    : Colors.blue,
          ),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // ⭐ FIX: Add Flexible to stop long names from pushing "(You)" off-screen and crashing
                    Flexible(
                      child: UserNameText(
                        uid: receiverUid,
                        style: TextStyle(
                          color: isPast
                              ? Colors.grey
                              : isCurrent
                                  ? Colors.green
                                  : Colors.blue,
                          fontWeight: isMe ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    if (isMe)
                      Text(" (${"you".tr()})",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(
                " — $monthLabel",
                style: TextStyle(
                    color: isPast
                        ? Colors.grey
                        : isCurrent
                            ? Colors.green
                            : Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }
}
