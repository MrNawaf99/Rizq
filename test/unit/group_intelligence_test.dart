// test/unit/group_intelligence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jam3iya_app/core/utils/group_intelligence.dart';
import 'package:jam3iya_app/models/group_model.dart';

void main() {
  group('GroupIntelligence Business Logic Tests', () {
    late Group baseGroup;

    setUp(() {
      baseGroup = Group(
        id: 'test_group_1',
        name: 'Family Savings',
        monthlyAmount: 1000,
        receiverName: 'User A',
        receiveDate: DateTime(2025, 1, 1),
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 6, 30),
        isCompleted: false,
        members: ['uid_1', 'uid_2', 'uid_3', 'uid_4', 'uid_5', 'uid_6'],
        pendingMembers: [],
        receiverOrder: ['uid_1', 'uid_2', 'uid_3', 'uid_4', 'uid_5', 'uid_6'],
        myUserId: 'uid_1',
        roles: {'uid_1': GroupRole.leader, 'uid_2': GroupRole.member},
        payments: {},
        paidMonths: [],
      );
    });

    test('totalMonths calculates exact duration inclusive of start and end months', () {
      final months = GroupIntelligence.totalMonths(baseGroup);
      expect(months, 6);
    });

    test('totalMonths calculates single-month group correctly', () {
      final singleMonthGroup = baseGroup.copyWith(
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 20),
      );
      expect(GroupIntelligence.totalMonths(singleMonthGroup), 1);
    });

    test('totalMonths across year boundary calculates correctly', () {
      final multiYearGroup = baseGroup.copyWith(
        startDate: DateTime(2024, 11, 1),
        endDate: DateTime(2025, 2, 28),
      );
      expect(GroupIntelligence.totalMonths(multiYearGroup), 4);
    });

    test('progress returns double between 0.0 and 1.0', () {
      final progress = GroupIntelligence.progress(baseGroup);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });

    test('currentReceiverIndex stays within receiverOrder bounds or returns -1', () {
      final index = GroupIntelligence.currentReceiverIndex(
        baseGroup,
        baseGroup.members.length,
      );
      expect(index, greaterThanOrEqualTo(-1));
      expect(index, lessThan(baseGroup.receiverOrder.length));
    });

    test('receiveAmount calculates product of monthlyAmount and count', () {
      final amount = GroupIntelligence.receiveAmount(baseGroup, 6);
      expect(amount, 6000);
    });

    test('isCompleted returns true if group is explicitly marked completed', () {
      final completedGroup = baseGroup.copyWith(isCompleted: true);
      expect(GroupIntelligence.isCompleted(completedGroup), isTrue);
    });

    test('isCompleted returns true if group is closed', () {
      final closedGroup = baseGroup.copyWith(isClosed: true);
      expect(GroupIntelligence.isCompleted(closedGroup), isTrue);
    });

    test('isCompleted returns false for active ongoing group with future end date', () {
      final activeGroup = baseGroup.copyWith(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 120)),
        isCompleted: false,
        isClosed: false,
      );
      expect(GroupIntelligence.isCompleted(activeGroup), isFalse);
    });
  });
}
