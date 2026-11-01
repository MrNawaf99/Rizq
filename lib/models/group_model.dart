// lib/models/group_model.dart

enum GroupRole {
  leader,
  assistant,
  member,
}

enum PaymentStatus { paid, pending, open, locked, missed }

class Group {
  final List<String> paidMonths;
  final String id;
  final String name;
  final int monthlyAmount;
  final String receiverName;
  final DateTime receiveDate;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final List<String> members;
  final String myUserId;
  final bool isClosed;
  final List<String> pendingMembers;
  final String monthlyMessage;
  final int notificationHour;
  final int notificationMinute;
  final List<String> receiverOrder;
  final Map<String, GroupRole> roles;

  /// monthKey -> list of userIds who paid
  final Map<String, List<String>> payments;
  final String groupCode;
  final bool distributionStarted;
  final String chatMode;
  final String lastReminderSentMonth;
  final bool allowMemberImageMessages;

  /// ⭐ Helper: دالة موحدة لإنشاء مفاتيح الأشهر
  static String generateMonthKey(DateTime date) {
    return "${date.year}-${date.month}";
  }

  int get totalMonths {
    return (endDate.year - startDate.year) * 12 +
        (endDate.month - startDate.month) +
        1;
  }

  GroupRole get myRole {
    return roles[myUserId] ?? GroupRole.member;
  }

  bool get isLeader => myRole == GroupRole.leader;

  bool get isAssistant => myRole == GroupRole.assistant;

  bool get canManage =>
      myRole == GroupRole.leader || myRole == GroupRole.assistant;

  /// ⭐ Helper: حساب عدد الطلبات المعلقة للمديرين
  int get pendingPaymentsCount {
    int count = 0;
    payments.forEach((key, value) {
      if (key.endsWith("_pending")) {
        count += value.length;
      }
    });
    return count;
  }

  bool hasUserPaid(String monthKey, String userId) {
    final list = payments[monthKey];
    if (list == null) return false;
    return list.contains(userId);
  }

  bool isMemberPaid(String monthKey, String member) {
    if (paidMonths.contains(monthKey)) return true;
    return payments[monthKey]?.contains(member) ?? false;
  }

  bool isMonthFullyPaid(String monthKey) {
    final paid = payments[monthKey] ?? [];
    return paid.length == members.length;
  }

  const Group({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.receiverName,
    required this.receiveDate,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.members,
    required this.myUserId,
    required this.roles,
    this.paidMonths = const [],
    this.payments = const {},
    this.groupCode = "",
    this.receiverOrder = const [],
    this.isClosed = false,
    this.pendingMembers = const [],
    this.monthlyMessage = "",
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.distributionStarted = false,
    this.chatMode = "all_members",
    this.lastReminderSentMonth = "",
    this.allowMemberImageMessages = false,
  });

  Group copyWith({
    String? id,
    String? name,
    int? monthlyAmount,
    String? receiverName,
    DateTime? receiveDate,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    List<String>? members,
    String? myUserId,
    bool? isClosed,
    List<String>? pendingMembers,
    String? monthlyMessage,
    int? notificationHour,
    int? notificationMinute,
    List<String>? receiverOrder,
    Map<String, GroupRole>? roles,
    List<String>? paidMonths,
    Map<String, List<String>>? payments,
    String? groupCode,
    bool? distributionStarted,
    String? chatMode,
    String? lastReminderSentMonth,
    bool? allowMemberImageMessages,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      receiverName: receiverName ?? this.receiverName,
      receiveDate: receiveDate ?? this.receiveDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      members: members ?? this.members,
      myUserId: myUserId ?? this.myUserId,
      isClosed: isClosed ?? this.isClosed,
      pendingMembers: pendingMembers ?? this.pendingMembers,
      monthlyMessage: monthlyMessage ?? this.monthlyMessage,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      receiverOrder: receiverOrder ?? this.receiverOrder,
      roles: roles ?? this.roles,
      paidMonths: paidMonths ?? this.paidMonths,
      payments: payments ?? this.payments,
      groupCode: groupCode ?? this.groupCode,
      distributionStarted: distributionStarted ?? this.distributionStarted,
      chatMode: chatMode ?? this.chatMode,
      lastReminderSentMonth:
          lastReminderSentMonth ?? this.lastReminderSentMonth,
      allowMemberImageMessages:
          allowMemberImageMessages ?? this.allowMemberImageMessages,
    );
  }
}
