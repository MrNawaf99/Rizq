// lib/screens/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/group_provider.dart';
import '../../widgets/group_card.dart';
import '../groups/group_details/group_details_screen.dart';
import '../../core/utils/group_intelligence.dart';
import '../../models/group_model.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkIntroBanner(); // ⭐ استدعاء الدالة الصحيحة المسؤولة عن عرض البانر الثابت
  }

  bool _showIntroBanner = false; // ⭐ متغير للتحكم بظهور البانر

  Future<void> _checkIntroBanner() async {
    final prefs = await SharedPreferences.getInstance();
    // ⭐ STRICT FIX: جلب معرف المستخدم الحالي لربط الرسالة بحسابه فقط
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    // نفحص ما إذا كان هذا المستخدم تحديداً قد ضغط على (X) مسبقاً
    final isDismissed = prefs.getBool('intro_banner_dismissed_$uid') ?? false;

    // تظهر البطاقة فقط وتبقى ثابتة إذا لم يسبق له إغلاقها
    if (!isDismissed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showIntroBanner = true);
      });
    }
  }

  // ⭐ دالة الإغلاق اليدوي الدائم
  Future<void> _dismissIntroBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    // ⭐ حفظ الإغلاق نهائياً لهذا الحساب تحديداً
    await prefs.setBool('intro_banner_dismissed_$uid', true);
    if (mounted) {
      setState(() => _showIntroBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // ⭐ Dependency for language instant updates
    final allGroups = context.watch<GroupProvider>().groups;

    final active =
        allGroups.where((g) => !GroupIntelligence.isCompleted(g)).toList();

    return Stack(
      // ⭐ التعديل هنا: أضفنا Stack
      children: [
        // 1️⃣ المحتوى الأساسي للصفحة (كما هو بدون تغيير)
        Container(
          color: const Color(0xFFF6F8F7),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Consumer<GroupProvider>(
                builder: (context, provider, _) {
                  final uid = provider.currentUserId;
                  final fullName = provider.getUserName(uid);

                  if (fullName == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.loadUserName(uid);
                    });
                  }

                  // جلب الاسم الأول فقط
                  final firstName =
                      (fullName != null && fullName.trim().isNotEmpty)
                          ? fullName.trim().split(' ').first
                          : "";

                  return Text(
                    firstName.isNotEmpty
                        ? "welcomeBackName".tr(args: [firstName])
                        : "${"welcomeBack".tr()} 👋",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // ⭐ PREMIUM DASHBOARD CARD
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F7B6C),
                      Color(0xFF0A5E52)
                    ], // ⭐ Subtle depth gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF0F7B6C).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: active.isEmpty
                    ? Center(
                        child: Text(
                          "noActiveGroup".tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      )
                    : Row(
                        children: [
                          // 📌 STATIC COLUMN (العناوين)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  height: 28,
                                  alignment: Alignment.centerLeft,
                                  child: Text("groupNameLabel".tr(),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500))),
                              const SizedBox(height: 16),
                              Container(
                                  height: 28,
                                  alignment: Alignment.centerLeft,
                                  child: Text("paymentStatusThisMonth".tr(),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500))),
                              const SizedBox(height: 16),
                              Container(
                                  height: 28,
                                  alignment: Alignment.centerLeft,
                                  child: Text("completedMonthsLabel".tr(),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500))),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // 📌 DYNAMIC COLUMNS (أعمدة الجروبات)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: active.map((group) {
                                  final currentMonthKey =
                                      Group.generateMonthKey(DateTime.now());
                                  final provider =
                                      context.read<GroupProvider>();
                                  final isPaidThisMonth = group.isMemberPaid(
                                      currentMonthKey, provider.currentUserId);
                                  final totalMonths =
                                      GroupIntelligence.totalMonths(group);
                                  final completedMonths =
                                      GroupIntelligence.passedMonths(group);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 1. Group Name
                                        Container(
                                            height: 28,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              group.name.length > 12
                                                  ? '${group.name.substring(0, 12)}...'
                                                  : group.name,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            )),
                                        const SizedBox(height: 16),
                                        // 2. Status Badge (Pill Design)
                                        Container(
                                            height: 28,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isPaidThisMonth
                                                    ? Colors.greenAccent
                                                        .withValues(alpha: 0.12)
                                                    : Colors.orangeAccent
                                                        .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: isPaidThisMonth
                                                        ? Colors.greenAccent
                                                            .withValues(alpha: 0.3)
                                                        : Colors.orangeAccent
                                                            .withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPaidThisMonth
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons.error_outline,
                                                    color: isPaidThisMonth
                                                        ? Colors.greenAccent
                                                        : Colors.orangeAccent,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isPaidThisMonth
                                                        ? "paidStatus".tr()
                                                        : "notPaidStatus".tr(),
                                                    style: TextStyle(
                                                        color: isPaidThisMonth
                                                            ? Colors.greenAccent
                                                            : Colors
                                                                .orangeAccent,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        const SizedBox(height: 16),
                                        // 3. Progress Score
                                        Container(
                                            height: 28,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "monthsProgress".tr(args: [
                                                completedMonths.toString(),
                                                totalMonths.toString()
                                              ]),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            )),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                "yourGroups".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...active.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GroupCard(
                      group: g,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailsScreen(group: g),
                          ),
                        );
                      },
                    ),
                  )),
              if (active.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text("no_active_groups".tr()),
                  ),
                ),
            ],
          ),
        ), // ⭐ إغلاق الـ Container الأساسي

        // 2️⃣ PREMIUM CORNER INTRO BANNER (البانر الجديد يضاف هنا)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          top: _showIntroBanner ? 16 : -150, // حركة Slide In/Out من الأعلى
          left: 16,
          right: 16, // لجعله يتوسط الشاشة بـ Padding
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                      color: const Color(0xFF0F7B6C).withValues(alpha: 0.2),
                      width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة معلومات أنيقة
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F7B6C).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Color(0xFF0F7B6C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    // النصوص والرابط
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "مرحباً بك في Jam3iya! 👋",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment:
                                WrapCrossAlignment.center, // محاذاة في المنتصف
                            children: [
                              const Text(
                                "لمعرفة المزيد عن التطبيق وميزاته، يمكنك زيارة قسم ",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.5),
                              ),
                              // ⭐ الرابط مع تأثير الضغط (Ripple Effect) الأنيق
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  splashColor: const Color(0xFF0F7B6C)
                                      .withValues(alpha: 0.2), // تأثير النقر
                                  highlightColor:
                                      const Color(0xFF0F7B6C).withValues(alpha: 0.1),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AboutScreen()));
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: Text(
                                      "حول التطبيق.",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF0F7B6C),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ⭐ زر الإغلاق السريع (Dismiss)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap:
                            _dismissIntroBanner, // استدعاء دالة الإغلاق الدائم
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child:
                              Icon(Icons.close, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ], // ⭐ إغلاق الـ Stack
    );
  } // إغلاق الدالة build
} // إغلاق الـ Class
