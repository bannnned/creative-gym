import 'dart:math' as math;

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  var _checkingSession = false;
  var _signingIn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    if (appDependencies.config.mode != DataSourceMode.mock) {
      _checkingSession = true;
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    final restored = await appDependencies.auth.restoreSession();
    if (!mounted) {
      return;
    }

    if (restored) {
      context.go(AppRoutes.challenges);
      return;
    }

    setState(() => _checkingSession = false);
  }

  Future<void> _continue() async {
    if (_checkingSession || _signingIn) {
      return;
    }

    setState(() {
      _signingIn = true;
      _errorMessage = null;
    });

    try {
      await appDependencies.auth.signInAsGuest();
      if (mounted) {
        context.go(AppRoutes.challenges);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _signingIn = false;
        _errorMessage = userErrorMessage(error);
      });
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _SmallMark(),
                    const SizedBox(width: 10),
                    Text(
                      'Creative Gym',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: compact ? 190 : 250,
                  child: AnimatedBuilder(
                    animation: _motionController,
                    builder: (context, _) {
                      final motion = reduceMotion
                          ? 0.5
                          : Curves.easeInOut.transform(_motionController.value);
                      return _CreativeDeck(motion: motion);
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  'Тренируй\nвзгляд.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                    height: 0.94,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Выбери челлендж → сними один кадр → проголосуй → '
                  'узнай результат.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 10),
                ],
                IgnorePointer(
                  ignoring: _checkingSession || _signingIn,
                  child: GlassButton(
                    key: const ValueKey('continue-button'),
                    label: _checkingSession || _signingIn
                        ? 'Подождите…'
                        : 'Начать',
                    onPressed: _continue,
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Демо-режим',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SmallMark extends StatelessWidget {
  const _SmallMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 17,
      ),
    );
  }
}

class _CreativeDeck extends StatelessWidget {
  const _CreativeDeck({required this.motion});

  final double motion;

  @override
  Widget build(BuildContext context) {
    final travel = motion - 0.5;

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-54 - travel * 5, 9 + travel * 4),
          child: Transform.rotate(
            angle: -0.13 - travel * 0.015,
            child: const _PreviewFrame(
              colors: [Color(0xFFDBA277), Color(0xFF563E3B)],
              composition: 0,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(54 + travel * 5, 4 - travel * 4),
          child: Transform.rotate(
            angle: 0.12 + travel * 0.015,
            child: const _PreviewFrame(
              colors: [Color(0xFF8FB5A6), Color(0xFF2B5147)],
              composition: 1,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -5 - travel * 9),
          child: Transform.rotate(
            angle: travel * 0.018,
            child: const _PreviewFrame(
              colors: [Color(0xFFF0C982), Color(0xFF465E54)],
              composition: 2,
              foreground: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.colors,
    required this.composition,
    this.foreground = false,
  });

  final List<Color> colors;
  final int composition;
  final bool foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: foreground ? 184 : 164,
      height: foreground ? 218 : 194,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: foreground ? 0.16 : 0.09),
            blurRadius: foreground ? 26 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _PreviewPainter(colors, composition),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.colors, this.composition);

  final List<Color> colors;
  final int composition;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final light = Paint()..color = Colors.white.withValues(alpha: 0.24);
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.17);

    if (composition == 0) {
      canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.26),
        size.width * 0.22,
        light,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.52,
          size.width * 0.62,
          size.height * 0.48,
        ),
        shade,
      );
      return;
    }

    if (composition == 1) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * 0.76, size.height * 0.18)
        ..lineTo(size.width, size.height * 0.45)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, shade);
      return;
    }

    for (var index = 0; index < 4; index++) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(-math.pi / 5 + index * 0.24);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 1.4,
          height: size.height * 0.07,
        ),
        index.isEven ? light : shade,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => false;
}
