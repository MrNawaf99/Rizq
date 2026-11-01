// lib/screens/groups/my_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_group_screen.dart';
import '../../providers/group_provider.dart';
import '../../widgets/group_card.dart';
import 'group_details/group_details_screen.dart';
import '../../core/utils/group_intelligence.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // ⭐ Dependency for language instant updates

    return Column(
      children: [
        TabBar(
          controller: tabController,
          indicatorColor: const Color(0xFF0F7B6C),
          indicatorWeight: 3,
          tabs: [Tab(text: "myGroups".tr()), Tab(text: "summary".tr())],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              buildGroupsTab(context),
              buildSummaryTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildGroupsTab(BuildContext context) {
    final allGroups = context.watch<GroupProvider>().groups;
    final active =
        allGroups.where((g) => !GroupIntelligence.isCompleted(g)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("currentGroups".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...active.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupCard(
                group: g,
                showGroupDetails: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsScreen(group: g),
                  ),
                ),
              ),
            )),
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text("no_active_groups".tr())),
          ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateGroupScreen(),
              ),
            );
          },
          child: Text("createGroupButton".tr()),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _showJoinDialog(context),
          child: Text("joinGroup".tr()),
        ),
      ],
    );
  }

  Widget buildSummaryTab(BuildContext context) {
    final allGroups = context.watch<GroupProvider>().groups;
    final activeGroups =
        allGroups.where((g) => !GroupIntelligence.isCompleted(g)).toList();

    if (activeGroups.isEmpty) {
      return Center(child: Text("no_active_groups".tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeGroups.length,
      itemBuilder: (context, index) {
        final g = activeGroups[index];
        final receiveAmount = g.monthlyAmount *
            (g.receiverOrder.isNotEmpty
                ? g.receiverOrder.length
                : g.members.length);

        final startFormatted =
            DateFormat.yMMM(context.locale.toString()).format(g.startDate);
        final endFormatted =
            DateFormat.yMMM(context.locale.toString()).format(g.endDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("₹${g.monthlyAmount} / ${'month'.tr()}",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "$startFormatted → $endFormatted",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text("${'youWillReceive'.tr()}: ",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      "₹$receiveAmount",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("joinGroup".tr()),
              content: TextField(
                controller: controller,
                enabled: !loading,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: "enter_group_code".tr(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.pop(dialogContext),
                  child: Text("cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final code = controller.text.trim().toUpperCase();
                          if (code.isEmpty) return;

                          setState(() => loading = true);
                          final provider = context.read<GroupProvider>();

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogContext);

                          try {
                            await provider.joinGroup(code);
                            if (!dialogContext.mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text("waiting_for_approval".tr())),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => loading = false);

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

                            messenger.showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text("join".tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
