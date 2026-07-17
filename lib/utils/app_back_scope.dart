import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackScope extends StatelessWidget {
  final Widget child;
  final bool allowSystemPop;
  final bool Function()? onBack;
  final String? fallbackRoute;

  const AppBackScope({
    super.key,
    required this.child,
    this.allowSystemPop = true,
    this.onBack,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Using WillPopScope for compatibility with Flutter 3.10.4
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        bool shouldPop = true;
        if (onBack != null) {
          shouldPop = onBack!();
        }

        if (shouldPop) {
          if (Navigator.of(context).canPop()) {
            return true;
          } else if (fallbackRoute != null) {
            context.go(fallbackRoute!);
            return false;
          }
          return allowSystemPop;
        }
        return false;
      },
      child: child,
    );
  }
}
