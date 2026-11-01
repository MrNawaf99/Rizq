// test/unit/group_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jam3iya_app/models/group_model.dart';

void main() {
  group('Group Model Unit Tests', () {
    test('Group model instantiation and getters work correctly', () {
      final now = DateTime(2025, 1, 1);
      final monthKey = Group.generateMonthKey(now); // '2025-1'

      final group = Group(
        id: 'grp_123',
        name: 'Friends Circle',
        monthlyAmount: 500,
        receiverName: 'Ahmed',
        receiveDate: now,
        startDate: now,
        endDate: DateTime(2025, 12, 31),
        isCompleted: false,
        members: ['user_leader', 'user_assistant', 'user_member'],
        pendingMembers: ['user_pending'],
        receiverOrder: ['user_leader', 'user_assistant', 'user_member'],
        myUserId: 'user_leader',
        roles: {
          'user_leader': GroupRole.leader,
          'user_assistant': GroupRole.assistant,
          'user_member': GroupRole.member,
        },
        payments: {
          monthKey: ['user_leader'],
        },
        paidMonths: [],
        chatMode: 'all_members',
        allowMemberImageMessages: false,
      );

      // Verify leader role and permissions
      expect(group.isLeader, isTrue);
      expect(group.canManage, isTrue);
      expect(group.myRole, GroupRole.leader);

      // Verify individual user payment
      expect(group.hasUserPaid(monthKey, 'user_leader'), isTrue);
      expect(group.hasUserPaid(monthKey, 'user_assistant'), isFalse);
      expect(group.isMemberPaid(monthKey, 'user_leader'), isTrue);
      expect(group.isMemberPaid(monthKey, 'user_assistant'), isFalse);

      // When entire month is in paidMonths, isMemberPaid returns true for all
      final allPaidGroup = group.copyWith(paidMonths: [monthKey]);
      expect(allPaidGroup.isMemberPaid(monthKey, 'user_assistant'), isTrue);
    });

    test('Assistant role has management permissions but is not leader', () {
      final now = DateTime(2025, 1, 1);
      final group = Group(
        id: 'grp_123',
        name: 'Friends Circle',
        monthlyAmount: 500,
        receiverName: 'Ahmed',
        receiveDate: now,
        startDate: now,
        endDate: DateTime(2025, 12, 31),
        isCompleted: false,
        members: ['user_leader', 'user_assistant'],
        pendingMembers: [],
        receiverOrder: ['user_leader', 'user_assistant'],
        myUserId: 'user_assistant',
        roles: {
          'user_leader': GroupRole.leader,
          'user_assistant': GroupRole.assistant,
        },
        payments: {},
        paidMonths: [],
      );

      expect(group.isLeader, isFalse);
      expect(group.canManage, isTrue);
      expect(group.myRole, GroupRole.assistant);
    });

    test('Regular member has no management permissions', () {
      final now = DateTime(2025, 1, 1);
      final group = Group(
        id: 'grp_123',
        name: 'Friends Circle',
        monthlyAmount: 500,
        receiverName: 'Ahmed',
        receiveDate: now,
        startDate: now,
        endDate: DateTime(2025, 12, 31),
        isCompleted: false,
        members: ['user_leader', 'user_member'],
        pendingMembers: [],
        receiverOrder: ['user_leader', 'user_member'],
        myUserId: 'user_member',
        roles: {
          'user_leader': GroupRole.leader,
          'user_member': GroupRole.member,
        },
        payments: {},
        paidMonths: [],
      );

      expect(group.isLeader, isFalse);
      expect(group.canManage, isFalse);
      expect(group.myRole, GroupRole.member);
    });

    test('generateMonthKey creates standard formatted string key (year-month)', () {
      final date = DateTime(2025, 6, 15);
      final key = Group.generateMonthKey(date);
      expect(key, '2025-6');
    });

    test('copyWith properly updates fields and preserves unchanged', () {
      final now = DateTime(2025, 1, 1);
      final group = Group(
        id: 'grp_1',
        name: 'Initial Name',
        monthlyAmount: 100,
        receiverName: 'First',
        receiveDate: now,
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        isCompleted: false,
        members: ['u1'],
        pendingMembers: [],
        receiverOrder: ['u1'],
        myUserId: 'u1',
        roles: {'u1': GroupRole.leader},
        payments: {},
        paidMonths: [],
      );

      final updated = group.copyWith(
        name: 'Updated Name',
        monthlyAmount: 200,
        isCompleted: true,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.monthlyAmount, 200);
      expect(updated.isCompleted, isTrue);
      expect(updated.id, 'grp_1');
      expect(updated.members, ['u1']);
    });
  });
}
