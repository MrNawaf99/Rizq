import 'package:flutter/material.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_drawer.dart';
import 'package:easy_localization/easy_localization.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;

  final Function(int) onSelectPage;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onSelectPage,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    context.locale; // ⭐ Dependency for language instant updates

    return Scaffold(
      appBar: AppAppBar(title: title),
      drawer: AppDrawer(onSelectPage: onSelectPage),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0F7B6C).withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF0F7B6C),
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(
              color: Colors.grey,
            );
          }),
          selectedIndex: currentIndex,
          onDestinationSelected: onSelectPage,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(
                Icons.home,
                color: Color(0xFF0F7B6C),
              ),
              label: "home".tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(
                Icons.groups,
                color: Color(0xFF0F7B6C),
              ),
              label: "groups".tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(
                Icons.person,
                color: Color(0xFF0F7B6C),
              ),
              label: "profile".tr(),
            ),
          ],
        ),
      ),
    );
  }
}
