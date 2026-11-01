// lib/screens/groups/group_details/chat_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jam3iya_app/core/config/feature_flags.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/group_model.dart';
import '../../../models/message_model.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/group_provider.dart';

class ChatTab extends StatefulWidget {
  final Group group;
  const ChatTab({super.key, required this.group});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final groupProvider = context.read<GroupProvider>();
    final myUid = groupProvider.currentUserId;

    final bool isLeadersOnly = widget.group.chatMode == 'leaders_only';
    final bool canChat = !isLeadersOnly || widget.group.canManage;

    return Column(
      children: [
        if (isLeadersOnly)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            color: Colors.orange.withValues(alpha: 0.1),
            child: Text(
              "chat_locked_msg".tr(), // 🌐 مترجم
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: chatProvider.watchMessages(widget.group.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text("error_loading_chat".tr())); // 🌐 مترجم
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return Center(
                    child: Text("no_messages_yet".tr(),
                        style: TextStyle(
                            color: Colors.grey.shade600))); // 🌐 مترجم
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == myUid;

                  // ⭐ تغليف فقاعة الشات بـ GestureDetector للضغط المطول
                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: msg.isDeleted
                          ? null
                          : () {
                              // 1. حساب الصلاحيات (Moderation Logic)
                              final bool canDelete =
                                  isMe || widget.group.canManage;
                              final bool hasText = msg.text.isNotEmpty;

                              // 2. إخفاء القائمة تماماً إذا لم يكن لديه أي صلاحية على هذه الرسالة
                              if (!canDelete && !hasText) return;

                              // 3. عرض قائمة WhatsApp-Style
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16))),
                                builder: (sheetContext) {
                                  return SafeArea(
                                    child: Wrap(
                                      children: [
                                        if (hasText)
                                          ListTile(
                                            leading: const Icon(Icons.copy,
                                                color: Colors.blue),
                                            title: Text("copy_message".tr()),
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: msg.text));
                                              Navigator.pop(sheetContext);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "message_copied"
                                                              .tr())));
                                            },
                                          ),
                                        if (canDelete)
                                          ListTile(
                                            leading: const Icon(Icons.delete,
                                                color: Colors.red),
                                            title: Text("delete_message".tr(),
                                                style: const TextStyle(
                                                    color: Colors.red)),
                                            onTap: () async {
                                              Navigator.pop(
                                                  sheetContext); // إغلاق الـ Bottom Sheet
                                              // تأكيد الحذف
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: Text(
                                                      "delete_message".tr()),
                                                  content: Text(
                                                      "delete_message_confirm"
                                                          .tr()),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: Text(
                                                            "cancel".tr())),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.red),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child:
                                                          Text("delete".tr()),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                chatProvider.softDeleteMessage(
                                                    groupId: widget.group.id,
                                                    messageId: msg.id,
                                                    uid: myUid);
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF0F7B6C) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.senderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF0F7B6C)),
                              ),
                            const SizedBox(height: 4),

                            // ⭐ المنطق الجديد لعرض الرسالة (WhatsApp Style)
                            if (msg.isDeleted)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.do_not_disturb_alt,
                                      size: 14,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    "message_deleted".tr(),
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 14),
                                  ),
                                ],
                              )
                            else if (FeatureFlags.imageFeaturesEnabled &&
                                msg.imageUrl.isNotEmpty)
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: InteractiveViewer(
                                          child: Image.network(msg.imageUrl))),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(msg.imageUrl,
                                      height: 150, fit: BoxFit.cover),
                                ),
                              )
                            else
                              Text(
                                msg.text,
                                style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                    fontSize: 15),
                              ),

                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat.Hm(context.locale.toString())
                                    .format(msg.createdAt),
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isMe ? Colors.white70 : Colors.black45),
                              ),
                            ),
                          ],
                        ), // إغلاق الـ Column
                      ), // إغلاق الـ Container
                    ), // ⭐✅ هذا هو قوس الـ GestureDetector الذي كان مفقوداً!
                  ); // إغلاق الـ Align
                },
              ); // إغلاق الـ ListView.builder
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // ⭐ زر رفع الصورة (مجمد تماماً عبر Feature Flag)
                if (FeatureFlags.imageFeaturesEnabled &&
                    (widget.group.isLeader ||
                        widget.group.allowMemberImageMessages))
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate,
                        color: Color(0xFF0F7B6C)),
                    onPressed: canChat
                        ? () async {
                            final picker = ImagePicker();
                            final messenger = ScaffoldMessenger.of(context);
                            // ⭐ PERFORMANCE FIX: تصغير الأبعاد والضغط لمنع الـ RAM Overload والـ UI Freeze
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 50, // ضغط أعلى
                              maxWidth: 1024, // منع الصور الضخمة (4K)
                              maxHeight: 1024,
                            );
                            if (picked != null && mounted) {
                              messenger.showSnackBar(
                                  SnackBar(content: Text("sending...".tr())));
                              final myName =
                                  groupProvider.getUserName(myUid) ?? "User";
                              await chatProvider.sendImageMessage(
                                  widget.group.id, File(picked.path), myName);
                            }
                          }
                        : null,
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: canChat,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: canChat
                          ? "type_message".tr()
                          : "chat_locked_hint".tr(), // 🌐 مترجم
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: borderSideNone(),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F8F7),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      canChat ? const Color(0xFF0F7B6C) : Colors.grey,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: canChat
                        ? () {
                            final text = _controller.text;
                            if (text.trim().isNotEmpty) {
                              final myName =
                                  groupProvider.getUserName(myUid) ?? "User";
                              chatProvider.sendMessage(
                                  widget.group.id, text, myName);
                              _controller.clear();
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BorderSide borderSideNone() => BorderSide.none;
}
