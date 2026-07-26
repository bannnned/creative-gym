import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void popOrGoBack(BuildContext context, {required String fallbackLocation}) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go(fallbackLocation);
}

class AppBackScope extends StatelessWidget {
  const AppBackScope({
    super.key,
    required this.fallbackLocation,
    required this.child,
  });

  final String fallbackLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(fallbackLocation);
        }
      },
      child: child,
    );
  }
}
