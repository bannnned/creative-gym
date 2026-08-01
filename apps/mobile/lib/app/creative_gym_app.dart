import 'dart:async';

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:app_links/app_links.dart';
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
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final Set<String> _handledLinks = {};

  @override
  void initState() {
    super.initState();
    _listenForAuthLinks();
  }

  Future<void> _listenForAuthLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleAuthLink,
      onError: (_) {},
    );
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleAuthLink(initialLink);
      }
    } catch (_) {
      // Deep links are optional in local/mock environments.
    }
  }

  Future<void> _handleAuthLink(Uri uri) async {
    if (uri.scheme != 'creativegym' ||
        uri.host != 'auth' ||
        uri.path != '/complete' ||
        !_handledLinks.add(uri.toString())) {
      return;
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      if (uri.queryParameters['error'] == 'identity_in_use') {
        _showMessage(
          'Этот способ входа связан с другим аккаунтом. Текущие работы сохранены.',
        );
      } else if (uri.queryParameters['error'] != null) {
        _showMessage('Не удалось войти. Попробуйте ещё раз.');
      }
      return;
    }
    try {
      await appDependencies.auth.exchangeCode(code);
      _router.go(AppRoutes.challenges);
    } catch (_) {
      _router.go(AppRoutes.login);
      _showMessage('Ссылка для входа устарела. Попробуйте ещё раз.');
    }
  }

  void _showMessage(String value) {
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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
        scaffoldMessengerKey: _messengerKey,
        routerConfig: _router,
      ),
    );
  }
}
