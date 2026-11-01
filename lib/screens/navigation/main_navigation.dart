import 'package:flutter/material.dart';

import '../../layouts/main_scaffold.dart';
import '../groups/my_groups_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadGroups();
      NotificationService.requestPermissionAndSaveToken();
    });
  }

  List<String> titles(BuildContext context) => [
        "app_name".tr(),
        "my_groups".tr(),
        "profile".tr(),
      ];

  @override
  Widget build(BuildContext context) {
    context.locale; // ⭐ Dependency for language instant updates

    const pages = [
      HomeScreen(),
      MyGroupsScreen(),
      ProfileScreen(),
    ];

    return MainScaffold(
      title: titles(context)[index],
      body: pages[index],
      currentIndex: index,
      onSelectPage: (i) {
        setState(() => index = i);
      },
    );
  }
}
