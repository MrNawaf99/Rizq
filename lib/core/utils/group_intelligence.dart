// lib/core/utils/group_intelligence.dart

import '../../models/group_model.dart';

class GroupIntelligence {
  static int totalMonths(Group group) {
    return (group.endDate.year - group.startDate.year) * 12 +
        group.endDate.month -
        group.startDate.month +
        1;
  }

  static String monthStatus(Group group, DateTime month) {
    final key = Group.generateMonthKey(month);

    if (group.paidMonths.contains(key)) {
      return "paid";
    }

    final completedCount = group.paidMonths.length;
    final thisIndex = (month.year - group.startDate.year) * 12 +
        month.month -
        group.startDate.month;

    if (thisIndex == completedCount) {
      return "pending";
    }

    if (thisIndex > completedCount) {
      return "locked";
    }

    return "missed";
  }

  static bool isCompleted(Group group) {
    final total = totalMonths(group);
    if (total == 0) return true;

    final now = DateTime.now();
    final start = DateTime(group.startDate.year, group.startDate.month);
    final current = DateTime(now.year, now.month);
    int elapsed =
        (current.year - start.year) * 12 + (current.month - start.month);

    // Trigger: الجمعية تعتبر منتهية إذا انقضت المدة الزمنية أو اكتملت الدفعات
    return elapsed >= total || group.paidMonths.length >= total;
  }

  static int passedMonths(Group group) {
    final now = DateTime.now();
    final start = DateTime(group.startDate.year, group.startDate.month);
    final current = DateTime(now.year, now.month);

    // إذا لم تبدأ الجمعية بعد
    if (current.isBefore(start)) return 0;

    // حساب الأشهر التي انقضت فعلياً (الفرق الزمني)
    int elapsed =
        (current.year - start.year) * 12 + (current.month - start.month);
    final total = totalMonths(group);

    // نضمن ألا يتجاوز الرقم الإجمالي وألا يقل عن الصفر
    return elapsed.clamp(0, total);
  }

  static double progress(Group group) {
    final total = totalMonths(group);
    if (total == 0) return 0.0;

    final passed = passedMonths(group);
    // حساب النسبة المئوية للتقدم الزمني
    return (passed / total).clamp(0.0, 1.0);
  }

  static int receiveAmount(Group group, int membersCount) {
    return group.monthlyAmount * membersCount;
  }

  static int currentReceiverIndex(Group group, int membersCount) {
    final order =
        group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;

    if (order.isEmpty) return 0;

    final now = DateTime.now();
    final start = DateTime(group.startDate.year, group.startDate.month);
    final current = DateTime(now.year, now.month);

    if (current.isBefore(start)) {
      return -1;
    }

    final elapsed =
        (current.year - start.year) * 12 + (current.month - start.month);
    return elapsed % order.length;
  }

  static int nextReceiverIndex(Group group, int membersCount) {
    final currentIndex = currentReceiverIndex(group, membersCount);
    if (currentIndex == -1) return 0;

    final order =
        group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;

    if (order.isEmpty) return 0;

    // ⭐ SAFE FIX: إيقاف الدوران (Loop) وإرجاع -1 للدلالة على نهاية الدورة
    if (currentIndex >= order.length - 1) return -1;

    return currentIndex + 1;
  }
}
