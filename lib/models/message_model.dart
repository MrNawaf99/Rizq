//lib/models/message_model.dart//

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  // ⭐ حقول الـ Soft Delete الجديدة
  final bool isDeleted;
  final String deletedBy;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl = "",
    required this.createdAt,
    this.isDeleted = false,
    this.deletedBy = "",
    this.deletedAt,
  });

  factory Message.fromFirestore(String id, Map<String, dynamic> data) {
    // ⭐ استرجاع كود تحويل الوقت الذي تم اختصاره بالخطأ
    final rawCreatedAt = data['createdAt'];
    DateTime parsedDate = DateTime.now();

    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    }

    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'user',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: parsedDate, // ✅ تم التصحيح هنا
      isDeleted: data['isDeleted'] ?? false,
      deletedBy: data['deletedBy'] ?? '',
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl, // ⭐ حفظ الصورة
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
