// lib/repositories/group_repository.dart

import '../models/group_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class GroupRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> joinGroupByCode(String code, String userId) async {
    final query = await _db
        .collection('groups')
        .where('groupCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception("not_found");

    final doc = query.docs.first;
    final ref = doc.reference;
    final userRef = _db.collection('users').doc(userId);

    String leaderId = "";
    String name = userId;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final userSnapshot = await transaction.get(userRef);

      if (!snapshot.exists) throw Exception("not_found");

      final data = snapshot.data()!;
      final bool isClosed = data['isClosed'] ?? false;

      if (isClosed) throw Exception("closed");

      final members = List<String>.from(data['members'] ?? []);
      final pending = List<String>.from(data['pendingMembers'] ?? []);

      if (members.contains(userId)) throw Exception("already_member");
      if (pending.contains(userId)) throw Exception("already_requested");

      pending.add(userId);
      name = userSnapshot.data()?['name'] ?? userId;
      final roles = Map<String, dynamic>.from(data['roles'] ?? {});

      final leaderEntry = roles.entries.where((e) => e.value == 'leader');
      leaderId = leaderEntry.isNotEmpty ? leaderEntry.first.key : members.first;

      transaction.update(ref, {"pendingMembers": pending});
    });

    final notificationRef =
        _db.collection('users').doc(leaderId).collection('notifications').doc();
    await notificationRef.set({
      "message": "join_request",
      "args": {"user": name},
      "createdAt": FieldValue.serverTimestamp(),
      "read": false,
    });
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> updatePayments({
    required String groupId,
    required Map<String, List<String>> payments,
  }) async {
    final ref = _db.collection('groups').doc(groupId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw Exception("Group not found");

      final data = snapshot.data()!;
      final members = List<String>.from(data['members'] ?? []);
      final paidMonths = List<String>.from(data['paidMonths'] ?? []);

      payments.forEach((monthKey, paidList) {
        if (monthKey.contains("_pending")) return;
        if (paidList.length == members.length &&
            !paidMonths.contains(monthKey)) {
          paidMonths.add(monthKey);
        }
      });

      transaction.update(ref, {
        "payments": payments,
        "paidMonths": paidMonths,
      });
    });
  }

  Future<void> createGroup(Group group) async {
    String code = _generateGroupCode();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) throw Exception("User not logged in");

    List<String> members = List<String>.from(group.members);
    if (!members.contains(uid)) {
      members.add(uid);
    }

    Map<String, String> rolesMap =
        group.roles.map((key, value) => MapEntry(key, value.name));
    rolesMap[uid] = 'leader';

    await _db.collection('groups').add({
      "name": group.name,
      "monthlyAmount": group.monthlyAmount,
      "startMonth":
          "${group.startDate.year.toString().padLeft(4, '0')}-${group.startDate.month.toString().padLeft(2, '0')}-01",
      "endMonth":
          "${group.endDate.year.toString().padLeft(4, '0')}-${group.endDate.month.toString().padLeft(2, '0')}-01",
      "distributionStarted": false,
      "members": members,
      "pendingMembers": [],
      "isClosed": false,
      "monthlyMessage": group.monthlyMessage,
      "notificationHour": group.notificationHour,
      "notificationMinute": group.notificationMinute,
      "myUserId": uid,
      "roles": rolesMap,
      "payments": {},
      "paidMonths": [],
      "groupCode": code.toUpperCase(),
      "receiverOrder":
          group.receiverOrder.isEmpty ? members : group.receiverOrder,
      "chatMode": "all_members",
      "lastReminderSentMonth": "",
      "allowMemberImageMessages": false,
    });
  }

  DateTime _safeParseDate(dynamic dateString, DateTime fallback) {
    if (dateString == null) return fallback;
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return fallback;
    }
  }

  Future<List<Group>> getGroups() async {
    final snapshot = await _db.collection('groups').get();
    return snapshot.docs
        .map((doc) => _mapDocToGroup(doc.id, doc.data(), "unknown"))
        .toList();
  }

  Stream<List<Group>> watchGroups(String userId) {
    return _db
        .collection('groups')
        .where(
          Filter.or(
            Filter('members', arrayContains: userId),
            Filter('pendingMembers', arrayContains: userId),
          ),
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _mapDocToGroup(doc.id, doc.data(), userId))
          .toList();
    });
  }

  Group _mapDocToGroup(String docId, Map<String, dynamic> data, String userId) {
    return Group(
      id: docId,
      name: data['name'] ?? '',
      monthlyAmount: data['monthlyAmount'] ?? 0,
      receiverName: '',
      receiveDate: DateTime.now(),
      startDate: _safeParseDate(data['startMonth'], DateTime.now()),
      endDate: _safeParseDate(
          data['endMonth'] ?? data['startMonth'], DateTime.now()),
      distributionStarted: data['distributionStarted'] ?? false,
      isCompleted: false,
      members: List<String>.from(data['members'] ?? []),
      pendingMembers: List<String>.from(data['pendingMembers'] ?? []),
      receiverOrder: List<String>.from(data['receiverOrder'] ?? []),
      myUserId: userId,
      isClosed: data['isClosed'] ?? false,
      monthlyMessage: data['monthlyMessage'] ?? "",
      notificationHour: data['notificationHour'] ?? 9,
      notificationMinute: data['notificationMinute'] ?? 0,
      roles:
          (data['roles'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(
                k,
                GroupRole.values.firstWhere((e) => e.name == v,
                    orElse: () => GroupRole.member),
              )),
      payments: Map<String, List<String>>.from((data['payments'] ?? {})
          .map((k, v) => MapEntry(k, List<String>.from(v)))),
      groupCode: data['groupCode'] ?? '',
      chatMode: data['chatMode'] ?? 'all_members',
      lastReminderSentMonth: data['lastReminderSentMonth'] ?? '',
      allowMemberImageMessages: data['allowMemberImageMessages'] ?? false,
    );
  }

  Future<void> sendPaymentReminder(
      {required Group group, required DateTime month}) async {
    final key = Group.generateMonthKey(month);
    final paid = group.payments[key] ?? [];
    final unpaidMembers =
        group.members.where((m) => !paid.contains(m)).toList();

    if (unpaidMembers.isEmpty) return;

    for (final uid in unpaidMembers) {
      await _db.collection('users').doc(uid).collection('notifications').add({
        "message": "payment_reminder",
        "args": {"month": key},
        "createdAt": FieldValue.serverTimestamp(),
        "read": false,
      });
    }
  }

  List<Group> getActiveGroups() => [];
  List<Group> getCompletedGroups() => [];
  List<Group> getAllGroups() => [];
}
