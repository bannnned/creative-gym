import 'package:creative_gym_mobile/shared/widgets/app_background.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, this.appBar, required this.body});

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: appBar,
      body: AppBackground(
        child: SafeArea(top: appBar == null, child: body),
      ),
    );
  }
}
