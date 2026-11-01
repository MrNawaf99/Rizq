// lib/widgets/countdown_text.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CountdownText extends StatefulWidget {
  final DateTime targetDate;

  const CountdownText({super.key, required this.targetDate});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  String format() {
    final diff = widget.targetDate.difference(DateTime.now());

    if (diff.isNegative) return "completed".tr();

    String two(int n) => n.toString().padLeft(2, '0');

    return "${diff.inDays}d ${two(diff.inHours % 24)}h ${two(diff.inMinutes % 60)}m ${two(diff.inSeconds % 60)}s";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "receive_after".tr(),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          format(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
