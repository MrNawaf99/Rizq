import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String message;
  final Map<String, dynamic>? args;
  final String? type; // ⭐ Added to handle UI routing/actions
  final String? groupId; // ⭐ Added to know which group this belongs to
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.message,
    this.args,
    this.type,
    this.groupId,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];

    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else {
      createdAt = DateTime.now();
    }

    return AppNotification(
      id: id,
      message: (data['message'] ?? '').toString(),
      args:
          data['args'] != null ? Map<String, dynamic>.from(data['args']) : null,
      type: data['type']?.toString(), // ⭐ Parse type
      groupId: data['groupId']?.toString(), // ⭐ Parse groupId
      createdAt: createdAt,
      read: data['read'] == true,
    );
  }
}
