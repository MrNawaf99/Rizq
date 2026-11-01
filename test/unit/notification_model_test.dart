// test/unit/notification_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jam3iya_app/models/notification_model.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('AppNotification.fromFirestore parses valid notification payload', () {
      final now = DateTime(2025, 6, 1, 14, 0);
      final data = {
        'message': 'payment_reminder',
        'args': {'month': '6/2025'},
        'type': 'payment_reminder',
        'groupId': 'grp_xyz',
        'createdAt': now,
        'read': false,
      };

      final notification = AppNotification.fromFirestore('notif_100', data);

      expect(notification.id, 'notif_100');
      expect(notification.message, 'payment_reminder');
      expect(notification.args, {'month': '6/2025'});
      expect(notification.type, 'payment_reminder');
      expect(notification.groupId, 'grp_xyz');
      expect(notification.read, isFalse);
      expect(notification.createdAt, now);
    });

    test('AppNotification handles null optional fields gracefully', () {
      final data = <String, dynamic>{
        'message': 'generic_alert',
        'read': true,
      };

      final notification = AppNotification.fromFirestore('notif_101', data);

      expect(notification.id, 'notif_101');
      expect(notification.message, 'generic_alert');
      expect(notification.args, isNull);
      expect(notification.type, isNull);
      expect(notification.groupId, isNull);
      expect(notification.read, isTrue);
      expect(notification.createdAt, isA<DateTime>());
    });
  });
}
