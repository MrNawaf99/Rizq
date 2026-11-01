// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Message>> watchMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> sendImageMessage(
      String groupId, File imageFile, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final ext = imageFile.path.split('.').last;
      final ref = FirebaseStorage.instance.ref().child(
          'groups/$groupId/chat/${DateTime.now().millisecondsSinceEpoch}.$ext');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      await _db.collection('groups').doc(groupId).collection('messages').add({
        'senderId': uid,
        'senderName': senderName,
        'text': '',
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Image send failed: $e");
    }
  }

  Future<void> sendMessage(
      String groupId, String text, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;

    await _db.collection('groups').doc(groupId).collection('messages').add({
      'senderId': uid,
      'senderName': senderName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChatMode(String groupId, String mode) async {
    await _db.collection('groups').doc(groupId).update({
      'chatMode': mode,
    });
  }

  Future<void> softDeleteMessage({
    required String groupId,
    required String messageId,
    required String uid,
  }) async {
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedBy': uid,
        'text': '',
        'imageUrl': '',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to delete message: $e");
    }
  }
}
