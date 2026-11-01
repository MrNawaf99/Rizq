// lib/widgets/group_card.dart
import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../core/utils/group_intelligence.dart';
import 'countdown_text.dart';
import '../widgets/user_name_text.dart';
import 'package:easy_localization/easy_localization.dart';

enum CardStatus { red, blue, green, grey }

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final bool showGroupDetails;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.showGroupDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPendingApproval = group.pendingMembers.contains(group.myUserId);
    final isDistributionNotStarted = !group.distributionStarted;
    final order =
        group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;

    // SAFE GUARD: Avoid crash if group has 0 active members somehow
    if (order.isEmpty) return const SizedBox();

    final totalMembers = order.length;
    final currentIndex =
        GroupIntelligence.currentReceiverIndex(group, totalMembers);
    final isTimeNotStarted = currentIndex == -1;

    final isCompleted = GroupIntelligence.isCompleted(group);

    // حساب المبلغ المدفوع الكلي للمستخدم
    int paidCount = 0;
    for (var entry in group.payments.entries) {
      if (entry.key.endsWith("_pending")) continue;
      if (entry.value.contains(group.myUserId)) {
        paidCount++;
      }
    }
    final totalPaid = paidCount * group.monthlyAmount;
    final receiveAmount = group.monthlyAmount * totalMembers;

    // 1. Red Cards (Pre-start states)
    if (isPendingApproval) {
      return _buildCard(
        context,
        title: group.name,
        status: CardStatus.red,
        showPaidBar: false,
        subtitleWidget:
            _buildRedSubtitle("waiting_leader_approval", group.monthlyAmount),
      );
    }

    if (isDistributionNotStarted) {
      return _buildCard(
        context,
        title: group.name,
        status: CardStatus.red,
        showPaidBar: false,
        subtitleWidget:
            _buildRedSubtitle("waiting_leader_start", group.monthlyAmount),
      );
    }

    if (isTimeNotStarted) {
      return _buildCard(
        context,
        title: group.name,
        status: CardStatus.red,
        showPaidBar: false,
        subtitleWidget:
            _buildRedSubtitle("group_not_started", group.monthlyAmount),
      );
    }

    // 2. Grey Cards (Completed Groups)
    if (isCompleted) {
      return _buildCard(
        context,
        title: group.name,
        status: CardStatus.grey,
        showPaidBar: true,
        totalPaid: totalPaid,
        subtitleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Group Completed",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              "you_received_amount".tr(args: [receiveAmount.toString()]),
              style: const TextStyle(
                  color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // 3. Active Groups (Blue or Green Cards)
    final myIndex = order.indexOf(group.myUserId);
    if (myIndex == -1) return const SizedBox(); // Fallback if user missing

    final currentReceiver = order[currentIndex];
    final hasNextReceiver = currentIndex < totalMembers - 1;
    final nextIndex = hasNextReceiver ? currentIndex + 1 : -1;
    final nextReceiver = hasNextReceiver ? order[nextIndex] : "";

    final isMyTurn = myIndex == currentIndex;
    final isNextTurn = hasNextReceiver && (myIndex == nextIndex);
    final alreadyReceived = myIndex < currentIndex;

    // ⭐ Helper Widget: لمنع تكرار الكود وعرض "اكتملت الجمعية" إن لم يوجد مستلم تالي
    final Widget nextReceiverWidget = !hasNextReceiver
        ? Text("jam3iya_completed_status".tr(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))
        : UserNameText(
            uid: nextReceiver,
            style: const TextStyle(fontWeight: FontWeight.w600));

    final status = isMyTurn ? CardStatus.green : CardStatus.blue;

    int monthsUntilTurn;
    if (myIndex >= currentIndex) {
      monthsUntilTurn = myIndex - currentIndex;
    } else {
      monthsUntilTurn = totalMembers - (currentIndex - myIndex);
    }

    final receiveDate = DateTime(
      group.startDate.year,
      group.startDate.month + currentIndex + monthsUntilTurn,
    );

    // === GROUP PAGE CARDS ===
    if (showGroupDetails) {
      Widget detailsContent;
      if (isMyTurn) {
        detailsContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("current_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text("your_turn".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 6),
            Text("next_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            nextReceiverWidget,
            const SizedBox(height: 6),
            Text("you_will_receive".tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text("₹$receiveAmount",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
          ],
        );
      } else if (isNextTurn) {
        detailsContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("current_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            UserNameText(
                uid: currentReceiver,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("next_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text("your_turn_n".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 6),
            Text("you_will_receive".tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text("₹$receiveAmount",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
          ],
        );
      } else if (alreadyReceived) {
        detailsContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("current_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            UserNameText(
                uid: currentReceiver,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("next_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            nextReceiverWidget,
            const SizedBox(height: 6),
            Text("already_received".tr(),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            Text("you_received_amount".tr(args: [receiveAmount.toString()]),
                style: const TextStyle(color: Color(0xFFD4AF37))),
          ],
        );
      } else {
        // Later in queue
        detailsContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("current_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            UserNameText(
                uid: currentReceiver,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("next_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            nextReceiverWidget,
            const SizedBox(height: 6),
            Text(
                "your_turn_date".tr(args: [
                  _monthName(receiveDate.month),
                  receiveDate.year.toString()
                ]),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text("you_will_receive".tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text("₹$receiveAmount",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
          ],
        );
      }
      return _buildCard(
        context,
        title: group.name,
        status: status,
        showPaidBar: true,
        totalPaid: totalPaid,
        subtitleWidget: detailsContent,
      );
    }
    // === HOME PAGE CARDS ===
    else {
      Widget homeContent;
      if (isMyTurn) {
        homeContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("your_turn".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 6),
            Text("you_will_receive".tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text("₹$receiveAmount",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
          ],
        );
      } else if (alreadyReceived) {
        homeContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("current_receiver".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            UserNameText(
                uid: currentReceiver,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text("already_received".tr(),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            Text("you_received_amount".tr(args: [receiveAmount.toString()]),
                style: const TextStyle(color: Color(0xFFD4AF37))),
          ],
        );
      } else {
        // Not My Turn (Future)
        homeContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("time_remaining".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 6),
            CountdownText(targetDate: receiveDate),
            const SizedBox(height: 6),
            Text("you_will_receive".tr(),
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text("₹$receiveAmount",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37))),
          ],
        );
      }
      return _buildCard(
        context,
        title: group.name,
        status: status,
        showPaidBar: true,
        totalPaid: totalPaid,
        subtitleWidget: homeContent,
      );
    }
  }

  Widget _buildRedSubtitle(String textKey, int amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textKey.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "₹$amount / ${'month'.tr()}",
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required CardStatus status,
    required Widget subtitleWidget,
    bool showPaidBar = false,
    int totalPaid = 0,
  }) {
    Color topColor;
    switch (status) {
      case CardStatus.red:
        topColor = const Color(0xFFE53935);
        break;
      case CardStatus.blue:
        topColor = Colors.blue;
        break;
      case CardStatus.green:
        topColor = Colors.green;
        break;
      case CardStatus.grey:
        topColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: topColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F7B6C)
                                  .withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Color(0xFF0F7B6C),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Divider(
                                  height: 16,
                                  thickness: 1,
                                  color: Colors.grey.shade200,
                                ),
                                const SizedBox(height: 6),
                                subtitleWidget,
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      if (showPaidBar) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8F7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "you_paid".tr(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "₹$totalPaid",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m];
  }
}
