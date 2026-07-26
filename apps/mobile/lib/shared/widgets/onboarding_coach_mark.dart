import 'dart:async';

import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class OnboardingCoachStep {
  const OnboardingCoachStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.body,
    this.align = ContentAlign.bottom,
  });

  final String id;
  final GlobalKey targetKey;
  final String title;
  final String body;
  final ContentAlign align;
}

TutorialCoachMark createOnboardingCoachMark({
  required BuildContext context,
  required List<OnboardingCoachStep> steps,
  required VoidCallback onFinish,
  required VoidCallback onSkip,
  FutureOr<void> Function(String id)? onTargetTap,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  return TutorialCoachMark(
    targets: [
      for (var index = 0; index < steps.length; index++)
        TargetFocus(
          identify: steps[index].id,
          keyTarget: steps[index].targetKey,
          shape: ShapeLightFocus.RRect,
          radius: 24,
          paddingFocus: 6,
          enableOverlayTab: false,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: steps[index].align,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              builder: (context, controller) => _OnboardingCoachBubble(
                key: ValueKey('onboarding-tooltip-${steps[index].id}'),
                title: steps[index].title,
                body: steps[index].body,
                actionLabel: index == steps.length - 1 ? 'Понятно' : 'Дальше',
                onNext: controller.next,
              ),
            ),
          ],
        ),
    ],
    colorShadow: Colors.black,
    opacityShadow: 0.16,
    paddingFocus: 6,
    pulseEnable: false,
    useSafeArea: true,
    alignSkip: Alignment.topRight,
    skipWidget: const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'Пропустить',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    ),
    focusAnimationDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    unFocusAnimationDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180),
    beforeFocus: (target) async {
      final targetContext = target.keyTarget?.currentContext;
      if (targetContext == null) {
        return;
      }
      await Scrollable.ensureVisible(
        targetContext,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    },
    onClickTarget: (target) {
      final id = target.identify;
      if (id is String) {
        return onTargetTap?.call(id);
      }
    },
    onFinish: onFinish,
    onSkip: () {
      onSkip();
      return true;
    },
    backgroundSemanticLabel: 'Подсказка по приложению',
  );
}

class _OnboardingCoachBubble extends StatelessWidget {
  const _OnboardingCoachBubble({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onNext,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 17, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                height: 1.4,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onNext, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }
}
