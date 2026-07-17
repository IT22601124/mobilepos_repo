import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

typedef AppBackHandler = FutureOr<bool> Function();

class AppBackScope extends StatelessWidget {
  final Widget child;
  final String? fallbackRoute;
  final AppBackHandler? onBack;
  final bool allowSystemPop;

  const AppBackScope({
    super.key,
    required this.child,
    this.fallbackRoute,
    this.onBack,
    this.allowSystemPop = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final customResult = onBack == null
            ? null
            : await Future.value(onBack!());
        if (!context.mounted) return;
        if (customResult == true) {
          if (allowSystemPop) SystemNavigator.pop();
          return;
        }
        if (customResult == false) return;

        if (context.canPop()) {
          context.pop();
          return;
        }

        final route = fallbackRoute;
        if (route != null) {
          context.go(route);
          return;
        }

        if (allowSystemPop) SystemNavigator.pop();
      },
      child: child,
    );
  }
}
