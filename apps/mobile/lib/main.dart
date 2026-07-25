import 'package:creative_gym_mobile/app/creative_gym_app.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  bootstrapApp();
  runApp(const CreativeGymApp());
}
