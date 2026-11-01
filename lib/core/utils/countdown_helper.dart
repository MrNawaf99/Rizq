import 'package:easy_localization/easy_localization.dart';

class CountdownHelper {
  static String format(DateTime date) {
    final diff = date.difference(DateTime.now());

    if (diff.isNegative) return "completed".tr();

    String two(int n) => n.toString().padLeft(2, '0');

    return "${diff.inDays}d "
        "${two(diff.inHours % 24)}h "
        "${two(diff.inMinutes % 60)}m "
        "${two(diff.inSeconds % 60)}s";
  }
}
