// lib/screens/groups/group_details/payments_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'payment_month_screen.dart';
import '../../../models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../core/utils/group_intelligence.dart';

class PaymentsTab extends StatelessWidget {
  final Group group;

  const PaymentsTab({super.key, required this.group});

  List<DateTime> _generateMonths(Group g) {
    final total = GroupIntelligence.totalMonths(g);
    return List.generate(
      total,
      (i) => DateTime(g.startDate.year, g.startDate.month + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final updatedGroup = provider.getGroup(group.id);
        if (updatedGroup == null) return const SizedBox();

        if (updatedGroup.isClosed) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "group_closed_payments_disabled".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        if (!updatedGroup.distributionStarted) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "waitingLeaderDistribution".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          );
        }

        final months = _generateMonths(updatedGroup);
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);

        return ListView.builder(
          itemCount: months.length,
          itemBuilder: (context, index) {
            final month = months[index];
            final key = Group.generateMonthKey(month);

            final paidList = updatedGroup.payments[key] ?? [];
            final isPaid = paidList.contains(updatedGroup.myUserId);
            final allPaid = updatedGroup.members.isNotEmpty &&
                updatedGroup.members.every((m) => paidList.contains(m));
            final pendingKey = "${key}_pending";
            final requested = updatedGroup.payments[pendingKey]
                    ?.contains(updatedGroup.myUserId) ??
                false;

            IconData icon;
            String label;
            VoidCallback? action;

            final monthDate = DateTime(month.year, month.month);
            final isCompleted = GroupIntelligence.isCompleted(updatedGroup);

            // ⭐ SAFE FIX #1: منطق حالات الأشهر المتوافق مع الاستخدام الواقعي

            if (isCompleted) {
              action = null; // تجميد الأزرار في وضع الأرشيف
              if (isPaid) {
                icon = Icons.check_circle;
                label = "paid".tr();
              } else {
                icon = Icons.lock;
                label = "locked".tr();
              }
            } else if (allPaid) {
              icon = Icons.check_circle;
              label = "paid".tr();
            } else if (monthDate.isAfter(currentMonth)) {
              // الأشهر المستقبلية مغلقة دائمًا
              icon = Icons.lock;
              label = "locked".tr();
            } else {
              // الأشهر الحالية والماضية
              if (updatedGroup.canManage) {
                // للإدارة: الشهر يظهر مفتوح ما دام لم يكتمل
                icon = Icons.hourglass_bottom;
                label = "open".tr();
              } else {
                // للعضو العادي
                if (isPaid) {
                  icon = Icons.check_circle;
                  label = "paid".tr();
                } else if (requested) {
                  icon = Icons.hourglass_top;
                  label = "underReview".tr();
                } else {
                  icon = Icons.payments;
                  label = "pay".tr();
                  action = () => provider.requestPayment(
                      updatedGroup, month, updatedGroup.myUserId);
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: monthDate == currentMonth
                    ? Colors.blue.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                // منع التفاعل في وضع الأرشيف
                onTap: isCompleted
                    ? null
                    : () {
                        if (updatedGroup.canManage &&
                            !monthDate.isAfter(currentMonth)) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PaymentMonthScreen(
                                      group: updatedGroup, month: month)));
                          return;
                        }
                        if (!updatedGroup.canManage &&
                            !monthDate.isAfter(currentMonth)) {
                          if (!requested && !isPaid) {
                            provider.requestPayment(
                                updatedGroup, month, updatedGroup.myUserId);
                          }
                        }
                      },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                    DateFormat.yMMM(context.locale.toString()).format(month)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: label == "paid".tr()
                          ? Colors.green
                          : label == "underReview".tr()
                              ? Colors.orange
                              : label == "pay".tr()
                                  ? Colors.blue
                                  : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: action,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: action != null ? Colors.blue : null,
                          fontWeight: action != null ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
