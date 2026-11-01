// lib/screens/groups/group_details/payment_month_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/group_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/user_name_text.dart';

class PaymentMonthScreen extends StatefulWidget {
  final Group group;
  final DateTime month;

  const PaymentMonthScreen({
    super.key,
    required this.group,
    required this.month,
  });

  @override
  State<PaymentMonthScreen> createState() => _PaymentMonthScreenState();
}

class _PaymentMonthScreenState extends State<PaymentMonthScreen> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat.yMMM(context.locale.toString()).format(widget.month);
    final provider = context.read<GroupProvider>();

    final key = Group.generateMonthKey(widget.month);
    final updatedGroup = provider.getGroup(widget.group.id);

    if (updatedGroup == null) return const Scaffold(body: SizedBox());

    final isMonthCompleted = updatedGroup.paidMonths.contains(key);

    return Scaffold(
      appBar: AppBar(
        title: Text(monthName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: (isMonthCompleted || isProcessing)
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => isProcessing = true);
                    try {
                      await provider.sendPaymentReminder(
                          updatedGroup, widget.month);
                      if (!mounted) return;
                      messenger.showSnackBar(
                          SnackBar(content: Text("reminderSent".tr())));
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                          SnackBar(content: Text("error_generic".tr())));
                    } finally {
                      if (mounted) {
                        setState(() => isProcessing = false);
                      }
                    }
                  },
          ),
          if (updatedGroup.canManage && !isMonthCompleted)
            IconButton(
              icon: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.done_all),
              tooltip: "markAllPaid".tr(),
              onPressed: isProcessing
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => isProcessing = true);
                      try {
                        await provider.markEntireMonthAsPaid(
                            updatedGroup, widget.month);
                        if (!mounted) return;
                        messenger.showSnackBar(
                            SnackBar(content: Text("monthCompleted".tr())));
                      } finally {
                        if (mounted) {
                          setState(() => isProcessing = false);
                        }
                      }
                    },
            ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          final updatedGroup = provider.getGroup(widget.group.id);
          if (updatedGroup == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final key = Group.generateMonthKey(widget.month);
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final thisMonth = DateTime(widget.month.year, widget.month.month);

          final isMonthCompleted = updatedGroup.paidMonths.contains(key);
          final isFuture = thisMonth.isAfter(currentMonth);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: updatedGroup.members.length,
            itemBuilder: (_, index) {
              final member = updatedGroup.members[index];
              final isPaid = updatedGroup.isMemberPaid(key, member);
              final pendingKey = "${key}_pending";
              final isPending =
                  updatedGroup.payments[pendingKey]?.contains(member) ?? false;

              Widget trailing;

              if (isMonthCompleted || isPaid) {
                trailing = const Icon(Icons.check_circle, color: Colors.green);
              } else if (isFuture) {
                trailing = const Icon(Icons.lock, color: Colors.grey);
              } else if (isPending) {
                if (updatedGroup.canManage) {
                  trailing = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setState(() => isProcessing = true);
                                try {
                                  await provider.markMemberAsPaid(
                                      updatedGroup, widget.month, member);
                                } finally {
                                  if (mounted) {
                                    setState(() => isProcessing = false);
                                  }
                                }
                              },
                        child: Text("confirm".tr()),
                      ),
                      TextButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setState(() => isProcessing = true);
                                try {
                                  await provider.rejectPaymentRequest(
                                      updatedGroup, widget.month, member);
                                } finally {
                                  if (mounted) {
                                    setState(() => isProcessing = false);
                                  }
                                }
                              },
                        child: Text("reject".tr(),
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                } else {
                  trailing = Text("underReview".tr());
                }
              } else {
                trailing = const Icon(Icons.hourglass_bottom);
              }

              return Card(
                child: ListTile(
                  onTap: (!isPaid &&
                          !isFuture &&
                          !isPending &&
                          updatedGroup.canManage &&
                          !isProcessing)
                      ? () async {
                          setState(() => isProcessing = true);
                          try {
                            await provider.markMemberAsPaid(
                                updatedGroup, widget.month, member);
                          } finally {
                            if (mounted) {
                              setState(() => isProcessing = false);
                            }
                          }
                        }
                      : null,
                  title: UserNameText(
                      uid: member,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: trailing,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
