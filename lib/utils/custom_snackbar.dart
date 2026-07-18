import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF10B981); // Emerald 500
        icon = Icons.check_circle_outline;
        iconColor = Colors.white;
        break;
      case SnackBarType.error:
        backgroundColor = colorScheme.error;
        icon = Icons.error_outline;
        iconColor = Colors.white;
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFF59E0B); // Amber 500
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.info:
        backgroundColor = colorScheme.primary;
        icon = Icons.info_outline;
        iconColor = Colors.white;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }
}
