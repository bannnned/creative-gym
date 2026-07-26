import 'package:creative_gym_mobile/shared/widgets/app_background.dart';
import 'package:creative_gym_mobile/shared/widgets/app_back_scope.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backFallbackLocation,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final String? backFallbackLocation;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      extendBodyBehindAppBar: false,
      appBar: appBar,
      body: AppBackground(
        child: SafeArea(top: appBar == null, child: body),
      ),
    );
    final fallbackLocation = backFallbackLocation;
    if (fallbackLocation == null) {
      return scaffold;
    }

    return AppBackScope(fallbackLocation: fallbackLocation, child: scaffold);
  }
}
