// test/unit/message_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jam3iya_app/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Message Model Tests', () {
    test('Message instantiation with default values', () {
      final now = DateTime(2025, 5, 1, 10, 30);
      final msg = Message(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Nawaf',
        text: 'Hello everyone!',
        createdAt: now,
      );

      expect(msg.id, 'msg_1');
      expect(msg.senderId, 'user_1');
      expect(msg.senderName, 'Nawaf');
      expect(msg.text, 'Hello everyone!');
      expect(msg.imageUrl, '');
      expect(msg.isDeleted, isFalse);
      expect(msg.deletedBy, '');
      expect(msg.deletedAt, isNull);
      expect(msg.createdAt, now);
    });

    test('Message.fromFirestore parses DateTime and soft-delete fields correctly', () {
      final now = DateTime(2025, 5, 1, 12, 0);
      final data = {
        'senderId': 'user_2',
        'senderName': 'Abdulrazzaq',
        'text': 'Important update',
        'imageUrl': 'https://example.com/img.jpg',
        'createdAt': now,
        'isDeleted': true,
        'deletedBy': 'admin_1',
      };

      final msg = Message.fromFirestore('doc_123', data);

      expect(msg.id, 'doc_123');
      expect(msg.senderId, 'user_2');
      expect(msg.senderName, 'Abdulrazzaq');
      expect(msg.text, 'Important update');
      expect(msg.imageUrl, 'https://example.com/img.jpg');
      expect(msg.isDeleted, isTrue);
      expect(msg.deletedBy, 'admin_1');
    });

    test('Message.toMap produces valid map with server timestamp', () {
      final msg = Message(
        id: 'm1',
        senderId: 'u1',
        senderName: 'User',
        text: 'Test',
        imageUrl: 'http://img.png',
        createdAt: DateTime.now(),
      );

      final map = msg.toMap();
      expect(map['senderId'], 'u1');
      expect(map['senderName'], 'User');
      expect(map['text'], 'Test');
      expect(map['imageUrl'], 'http://img.png');
      expect(map.containsKey('createdAt'), isTrue);
    });
  });
}
