// lib/widgets/user_name_text.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/group_provider.dart';

class UserNameText extends StatelessWidget {
  final String uid;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const UserNameText({
    super.key,
    required this.uid,
    this.style,
    this.prefix = "",
    this.suffix = "",
  });

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox();

    final provider = context.watch<GroupProvider>();
    final cachedName = provider.getUserName(uid);

    if (cachedName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadUserName(uid);
      });
      return Text(
        "$prefix...$suffix",
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }

    // FIX: Fallback accurately dynamically based on instant translation context, NO MORE RAW UIDs
    final displayName = cachedName.isEmpty ? "user".tr() : cachedName;

    return Text(
      "$prefix$displayName$suffix",
      style: style,
      overflow: TextOverflow.ellipsis,
    );
  }
}
