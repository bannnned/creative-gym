import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return MaterialApp.router(
      title: 'Creative Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
