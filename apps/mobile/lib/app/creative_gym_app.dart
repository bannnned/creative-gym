import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class CreativeGymApp extends StatefulWidget {
  const CreativeGymApp({super.key});

  @override
  State<CreativeGymApp> createState() => _CreativeGymAppState();
}

class _CreativeGymAppState extends State<CreativeGymApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWidgets.wrap(
      theme: GlassThemeData.simple(
        blur: 7,
        thickness: 18,
        quality: GlassQuality.standard,
        borderRadius: AppTheme.radiusM,
      ),
      child: MaterialApp.router(
        title: 'Creative Gym',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
