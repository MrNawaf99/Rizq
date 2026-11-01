// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

// ⚠️ DEPRECATION WARNING:
// This class conflicts with the `AppColors` class declared in `app_theme.dart`.
// It is highly recommended to merge these static properties into `app_theme.dart`
// and delete this file to prevent import collisions.

@Deprecated("Merged with AppColors inside app_theme.dart")
class DeprecatedAppColors {
  static const primary = Colors.green;

  /// Home card semantics
  static const turnSoon = Colors.green;
  static const turnLater = Colors.blue;
  static const completed = Colors.grey;
}
