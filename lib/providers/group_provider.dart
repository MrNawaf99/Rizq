// lib/providers/group_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../repositories/group_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/group_intelligence.dart';

class GroupProvider extends ChangeNotifier {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  final GroupRepository _repo = GroupRepository();
  StreamSubscription<List<Group>>? _groupsSub;

  List<Group> _groups = [];
  List<Group> get groups => _groups;

  @override
  void dispose() {
    _groupsSub?.cancel();
    super.dispose();
  }

  List<String> resolveReceiverOrder(Group group) {
    return group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members;
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = groups[groupIndex];

    if (group.roles[memberId] == GroupRole.leader) {
      throw Exception("Cannot remove group leader");
    }

    if (group.myRole == GroupRole.assistant &&
        group.roles[memberId] == GroupRole.assistant) {
      throw Exception("Assistant cannot remove another assistant");
    }

    if (group.members.length <= 2) {
      throw Exception("Group must contain at least 2 members");
    }

    final updatedMembers = List<String>.from(group.members)..remove(memberId);
    final updatedOrder = List<String>.from(group.receiverOrder)
      ..remove(memberId);

    final updatedRoles = Map<String, String>.from(
        group.roles.map((k, v) => MapEntry(k, v.name)));
    updatedRoles.remove(memberId);

    await FirebaseFirestore.instance.collection("groups").doc(groupId).update({
      "members": updatedMembers,
      "receiverOrder": updatedOrder,
      "roles": updatedRoles,
    });

    _groups[groupIndex] = group.copyWith(
      members: updatedMembers,
      receiverOrder: updatedOrder,
      roles: updatedRoles.map((k, v) =>
          MapEntry(k, GroupRole.values.firstWhere((e) => e.name == v))),
    );
    notifyListeners();
  }

  Future<void> makeMember({
    required String groupId,
    required String memberId,
  }) async {
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;
    final group = groups[groupIndex];

    if (!group.isLeader) throw Exception("Only leader can change roles");

    await FirebaseFirestore.instance.collection("groups").doc(groupId).update({
      "roles.$memberId": "member",
    });

    final newRoles = Map<String, GroupRole>.from(group.roles);
    newRoles[memberId] = GroupRole.member;

    _groups[groupIndex] = group.copyWith(roles: newRoles);
    notifyListeners();
  }

  Future<void> makeAssistant({
    required String groupId,
    required String memberId,
  }) async {
    final groupIndex = groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = groups[groupIndex];

    if (!group.isLeader) throw Exception("Only leader can assign roles");

    if (group.members.isEmpty || group.members.first == memberId) return;

    final updatedRoles = Map<String, String>.from(
      group.roles.map((k, v) => MapEntry(k, v.name)),
    );
    updatedRoles[memberId] = "assistant";

    await FirebaseFirestore.instance.collection("groups").doc(groupId).update({
      "roles": updatedRoles,
    });

    final newRoles = Map<String, GroupRole>.from(group.roles);
    newRoles[memberId] = GroupRole.assistant;

    _groups[groupIndex] = group.copyWith(roles: newRoles);
    notifyListeners();
  }

  Future<void> startDistribution(Group group) async {
    final ref = FirebaseFirestore.instance.collection("groups").doc(group.id);
    await ref.update({
      "distributionStarted": true,
      "receiverOrder":
          group.receiverOrder.isNotEmpty ? group.receiverOrder : group.members,
    });
  }

  Future<void> fixReceiverOrderIfEmpty(Group group) async {
    if (group.receiverOrder.isNotEmpty) return;
    await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
      "receiverOrder": group.members,
    });
  }

  Future<void> deleteGroup(Group group) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.id)
        .delete();
  }

  final Map<String, String> _userNameCache = {};

  String? getUserName(String uid) => _userNameCache[uid];

  void updateCachedUserName(String uid, String newName) {
    _userNameCache[uid] = newName;
    notifyListeners();
  }

  Future<void> loadUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        _userNameCache[uid] = doc.data()?['name'] ?? '';
      } else {
        _userNameCache[uid] = '';
      }
    } catch (_) {
      _userNameCache[uid] = '';
    }
    notifyListeners();
  }

  Future<void> preloadUserNames(List<String> uids) async {
    final missing =
        uids.where((uid) => !_userNameCache.containsKey(uid)).toList();

    if (missing.isEmpty) return;

    for (var i = 0; i < missing.length; i += 30) {
      final chunk = missing.skip(i).take(30).toList();

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          _userNameCache[doc.id] = doc.data()['name'] ?? '';
        }
      } catch (e) {
        debugPrint("Failed to load chunk of usernames: $e");
      }
    }
    notifyListeners();
  }

  Future<void> updateGroupSettings(
    Group group,
    DateTime newStart,
    DateTime newEnd,
    List<String> newOrder,
    String message,
    int hour,
    int minute,
  ) async {
    if (group.isClosed) throw Exception("Group is closed");

    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);
    await ref.update({
      "startMonth":
          "${newStart.year.toString().padLeft(4, '0')}-${newStart.month.toString().padLeft(2, '0')}-01",
      "endMonth":
          "${newEnd.year.toString().padLeft(4, '0')}-${newEnd.month.toString().padLeft(2, '0')}-01",
      "receiverOrder": newOrder,
      "monthlyMessage": message,
      "notificationHour": hour,
      "notificationMinute": minute,
    });

    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(
        startDate: newStart,
        endDate: newEnd,
        receiverOrder: newOrder,
        monthlyMessage: message,
        notificationHour: hour,
        notificationMinute: minute,
      );
      notifyListeners();
    }
  }

  Future<void> closeGroup(Group group) async {
    await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
      "isClosed": true,
    });
  }

  Future<void> markEntireMonthAsPaid(Group group, DateTime month) async {
    final key = Group.generateMonthKey(month);
    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      final members = List<String>.from(data['members'] ?? []);
      final payments = Map<String, dynamic>.from(data['payments'] ?? {});
      final paidMonths = List<String>.from(data['paidMonths'] ?? []);

      payments[key] = members;
      if (!paidMonths.contains(key)) paidMonths.add(key);

      transaction.update(ref, {"payments": payments, "paidMonths": paidMonths});
    });

    final index = _groups.indexWhere((g) => g.id == group.id);

    if (index != -1) {
      final old = _groups[index];

      _groups[index] = old.copyWith(
        paidMonths: old.paidMonths.contains(key)
            ? old.paidMonths
            : [...old.paidMonths, key],
        payments: {...old.payments, key: List<String>.from(old.members)},
      );
      notifyListeners();
    }
  }

  Future<void> approveMember(Group group, String userId) async {
    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      final members = List<String>.from(data['members'] ?? []);
      final pending = List<String>.from(data['pendingMembers'] ?? []);
      final roles = Map<String, dynamic>.from(data['roles'] ?? {});

      if (!pending.contains(userId)) return;

      pending.remove(userId);
      members.add(userId);
      roles[userId] = 'member';

      final receiverOrder = List<String>.from(data['receiverOrder'] ?? []);
      if (!receiverOrder.contains(userId)) receiverOrder.add(userId);

      transaction.update(ref, {
        "members": members,
        "pendingMembers": pending,
        "roles": roles,
        "receiverOrder": receiverOrder,
      });
    });

    await createNotification(
        uid: userId,
        text: "you_were_approved",
        type: "approved",
        groupId: group.id);
  }

  Future<void> rejectMember(Group group, String userId) async {
    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      final pending = List<String>.from(data['pendingMembers'] ?? []);
      if (!pending.contains(userId)) return;
      pending.remove(userId);
      transaction.update(ref, {"pendingMembers": pending});
    });

    await createNotification(
        uid: userId,
        text: "your_request_rejected",
        type: "rejected",
        groupId: group.id);
  }

  Future<void> joinGroup(String code) async {
    try {
      await _repo.joinGroupByCode(code, currentUserId);
    } catch (e) {
      if (e.toString().contains("closed")) throw Exception("closed");
      rethrow;
    }
  }

  Group? getGroup(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Group> get all => _groups;

  List<Group> get active =>
      _groups.where((g) => !GroupIntelligence.isCompleted(g)).toList();
  List<Group> get completed =>
      _groups.where((g) => GroupIntelligence.isCompleted(g)).toList();

  void markMonthAsPaid(Group group, DateTime month) {
    final key = Group.generateMonthKey(month);

    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index == -1) return;

    final old = _groups[index];
    if (old.paidMonths.contains(key)) return;

    _groups[index] = old.copyWith(paidMonths: [...old.paidMonths, key]);
    notifyListeners();
  }

  Future<void> markMemberAsPaid(
      Group group, DateTime month, String member) async {
    final key = Group.generateMonthKey(month);
    final pendingKey = "${key}_pending";
    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};

      final payments = Map<String, dynamic>.from(data['payments'] ?? {});
      final paidList = List<String>.from(payments[key] ?? []);
      final pendingList = List<String>.from(payments[pendingKey] ?? []);

      final membersList = List<String>.from(data['members'] ?? []);
      final paidMonthsList = List<String>.from(data['paidMonths'] ?? []);

      if (!paidList.contains(member)) paidList.add(member);
      pendingList.remove(member);
      payments[key] = paidList;
      payments[pendingKey] = pendingList;

      if (paidList.length == membersList.length &&
          !paidMonthsList.contains(key)) {
        paidMonthsList.add(key);
      }

      transaction
          .update(ref, {"payments": payments, "paidMonths": paidMonthsList});
    });

    final index = _groups.indexWhere((g) => g.id == group.id);

    if (index != -1) {
      final old = _groups[index];

      final newPayments = Map<String, List<String>>.from(old.payments);
      final list = List<String>.from(newPayments[key] ?? []);

      if (!list.contains(member)) list.add(member);
      newPayments[key] = list;

      List<String> newPaidMonths = List.from(old.paidMonths);
      if (list.length == old.members.length && !newPaidMonths.contains(key)) {
        newPaidMonths.add(key);
      }

      _groups[index] =
          old.copyWith(payments: newPayments, paidMonths: newPaidMonths);
      notifyListeners();
    }

    await createNotification(
      uid: member,
      text: "payment_approved",
      args: {"month": "${month.month}/${month.year}"},
      type: "payment_approved",
      groupId: group.id,
    );
  }

  Future<void> requestPayment(
      Group group, DateTime month, String member) async {
    if (group.isClosed) throw Exception("Group is closed");

    final key = Group.generateMonthKey(month);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index == -1) return;

    final old = _groups[index];
    final newPayments = Map<String, List<String>>.from(old.payments);
    final pendingKey = "${key}_pending";
    final pending = List<String>.from(newPayments[pendingKey] ?? []);

    if (pending.contains(member)) return;
    pending.add(member);
    newPayments[pendingKey] = pending;

    await _repo.updatePayments(groupId: group.id, payments: newPayments);

    final targetUids = <String>{};
    for (var entry in group.roles.entries) {
      if (entry.value == GroupRole.leader ||
          entry.value == GroupRole.assistant) {
        targetUids.add(entry.key);
      }
    }

    if (targetUids.isEmpty && group.members.isNotEmpty) {
      targetUids.add(group.members.first);
    }

    String memberName = member;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(member)
          .get();
      if (doc.exists && doc.data() != null) {
        memberName = doc.data()?['name'] ?? member;
      }
    } catch (_) {}

    for (var uid in targetUids) {
      await createNotification(
        uid: uid,
        text: "payment_request",
        args: {"user": memberName, "month": "${month.month}/${month.year}"},
        type: "payment_request",
        groupId: group.id,
      );
    }
  }

  Future<void> createNotification({
    required String uid,
    required String text,
    required String type,
    Map<String, dynamic>? args,
    String? groupId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
      "message": text,
      "args": args ?? {},
      "createdAt": FieldValue.serverTimestamp(),
      "read": false,
      "type": type,
      "groupId": groupId,
    });
  }

  Future<void> rejectPaymentRequest(
      Group group, DateTime month, String member) async {
    final key = Group.generateMonthKey(month);

    final pendingKey = "${key}_pending";
    final ref = FirebaseFirestore.instance.collection('groups').doc(group.id);

    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};

    final payments = Map<String, List<String>>.from(
      (data['payments'] ?? {}).map((k, v) => MapEntry(k, List<String>.from(v))),
    );

    final pending = List<String>.from(payments[pendingKey] ?? []);
    pending.remove(member);
    payments[pendingKey] = pending;

    await ref.update({"payments": payments});

    await createNotification(
      uid: member,
      text: "your_request_rejected",
      type: "payment_rejected",
      groupId: group.id,
    );
  }

  Future<void> loadGroups() async {
    await _groupsSub?.cancel();

    _groupsSub = _repo.watchGroups(currentUserId).listen((groups) {
      for (var g in groups) {
        fixReceiverOrderIfEmpty(g);
      }
      _groups = groups;
      notifyListeners();
    });
  }

  Future<void> addGroup(Group group) async {
    await _repo.createGroup(group);
  }

  Future<void> sendPaymentReminder(Group group, DateTime month) async {
    await _repo.sendPaymentReminder(group: group, month: month);
  }

  void updateGroup(Group updated) {
    final index = _groups.indexWhere((g) => g.id == updated.id);

    if (index != -1) {
      _groups[index] = updated;
      notifyListeners();
    }
  }
}
