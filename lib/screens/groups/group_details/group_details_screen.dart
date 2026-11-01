// lib/screens/groups/group_details/group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jam3iya_app/screens/groups/group_details/chat_tab.dart';
import '../../../models/group_model.dart';
import 'overview_tab.dart';
import 'schedule_tab.dart';
import 'payments_tab.dart';
import 'members_tab.dart';
import 'package:provider/provider.dart';
import '../../../providers/group_provider.dart';
import 'manage_tab.dart';
import '../../../core/utils/group_intelligence.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // ⭐ SAFE FIX #2: تحميل أسماء جميع الأعضاء مسبقاً قبل عرض الشاشات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<GroupProvider>();
        final g = provider.getGroup(widget.group.id) ?? widget.group;
        final allUids = [...g.members, ...g.pendingMembers, ...g.receiverOrder];
        provider.preloadUserNames(allUids.toSet().toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final updatedGroup = provider.getGroup(widget.group.id);

        if (updatedGroup == null) {
          return Scaffold(
            appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Group data unavailable or deleted."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back"),
                  )
                ],
              ),
            ),
          );
        }

        if (updatedGroup.pendingMembers.contains(updatedGroup.myUserId)) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(updatedGroup.name),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "waiting_for_approval".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(
                updatedGroup.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              actions: [
                // منع الدخول للإدارة إذا انتهت الجمعية
                if (updatedGroup.canManage &&
                    !GroupIntelligence.isCompleted(updatedGroup))
                  IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFF0F7B6C)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageTab(group: updatedGroup),
                        ),
                      );
                    },
                  ),
              ],
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF0F7B6C),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0F7B6C),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: "overview".tr()),
                  Tab(text: "schedule".tr()),
                  // ⭐ نقل تبويب الشات ليكون الثالث
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18),
                        const SizedBox(width: 4),
                        Text("chat_tab_title".tr()), // 🌐 مترجم
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("payments".tr()),
                        if (updatedGroup.canManage &&
                            updatedGroup.pendingPaymentsCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              updatedGroup.pendingPaymentsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("members".tr()),
                        if (updatedGroup.pendingMembers.isNotEmpty &&
                            updatedGroup.canManage)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              updatedGroup.pendingMembers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                OverviewTab(group: updatedGroup),
                ScheduleTab(group: updatedGroup),
                ChatTab(group: updatedGroup),
                PaymentsTab(group: updatedGroup),
                MembersTab(group: updatedGroup),
              ],
            ),
          ),
        );
      },
    );
  }
}
