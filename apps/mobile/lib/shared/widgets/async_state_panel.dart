import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum AsyncLoadingLayout { detail, list, photo, voting, profile }

class AsyncContentTransition extends StatelessWidget {
  const AsyncContentTransition({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

class AsyncLoadingPanel extends StatelessWidget {
  const AsyncLoadingPanel({
    super.key,
    this.message = 'Загрузка...',
    this.layout = AsyncLoadingLayout.detail,
  });

  final String message;
  final AsyncLoadingLayout layout;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effect = reduceMotion
        ? const SolidColorEffect(color: Color(0xFFE7EAE5))
        : const PulseEffect(
            from: Color(0xFFF0F2ED),
            to: Color(0xFFE0E5E0),
            duration: Duration(milliseconds: 1150),
          );
    return Semantics(
      label: message,
      child: ExcludeSemantics(
        child: Skeletonizer.zone(
          effect: effect,
          ignorePointers: true,
          child: _SkeletonLayout(layout: layout),
        ),
      ),
    );
  }
}

class _SkeletonLayout extends StatelessWidget {
  const _SkeletonLayout({required this.layout});

  final AsyncLoadingLayout layout;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      AsyncLoadingLayout.list => const _SkeletonList(),
      AsyncLoadingLayout.photo => const _SkeletonPhoto(),
      AsyncLoadingLayout.voting => const _SkeletonVoting(),
      AsyncLoadingLayout.profile => const _SkeletonProfile(),
      AsyncLoadingLayout.detail => const _SkeletonDetail(),
    };
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-list'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _SkeletonLine(widthFactor: 0.28, height: 18),
        const SizedBox(height: 14),
        for (var index = 0; index < 3; index++) ...[
          const AspectRatio(
            aspectRatio: 16 / 8.4,
            child: _SkeletonBlock(radius: 24),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _SkeletonDetail extends StatelessWidget {
  const _SkeletonDetail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-detail'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkeletonLine(widthFactor: 0.62, height: 30),
        SizedBox(height: 12),
        _SkeletonLine(widthFactor: 0.38),
        SizedBox(height: 28),
        AspectRatio(aspectRatio: 16 / 10, child: _SkeletonBlock(radius: 24)),
        SizedBox(height: 24),
        _SkeletonLine(widthFactor: 0.88),
        SizedBox(height: 10),
        _SkeletonLine(widthFactor: 0.72),
        SizedBox(height: 28),
        _SkeletonBlock(height: 54, radius: 18),
      ],
    );
  }
}

class _SkeletonPhoto extends StatelessWidget {
  const _SkeletonPhoto();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-photo'),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _SkeletonLine(widthFactor: 0.58, height: 26),
        const SizedBox(height: 10),
        const _SkeletonLine(widthFactor: 0.34),
        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 430),
            child: const AspectRatio(
              aspectRatio: 4 / 5,
              child: _SkeletonBlock(radius: 22),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _SkeletonLine(widthFactor: 0.46, height: 20),
        const SizedBox(height: 18),
        const _SkeletonBlock(height: 54, radius: 18),
      ],
    );
  }
}

class _SkeletonVoting extends StatelessWidget {
  const _SkeletonVoting();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('loading-skeleton-voting'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          const _SkeletonLine(widthFactor: 0.62, height: 26),
          const SizedBox(height: 10),
          const _SkeletonLine(widthFactor: 0.18),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _SkeletonBlock(radius: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _SkeletonBlock(radius: 20),
                ),
              ),
            ],
          ),
          const Spacer(),
          const _SkeletonLine(widthFactor: 0.42),
          const SizedBox(height: 18),
          const _SkeletonBlock(height: 54, radius: 18),
        ],
      ),
    );
  }
}

class _SkeletonProfile extends StatelessWidget {
  const _SkeletonProfile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-profile'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Center(child: Bone.circle(size: 104)),
        const SizedBox(height: 18),
        const Center(child: Bone.text(width: 150, fontSize: 24)),
        const SizedBox(height: 26),
        const _SkeletonBlock(height: 132, radius: 24),
        const SizedBox(height: 26),
        const _SkeletonLine(widthFactor: 0.28, height: 22),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var index = 0; index < 6; index++)
              const _SkeletonBlock(radius: 3),
          ],
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.widthFactor, this.height = 14});

  final double? widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final line = Bone(
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
    if (widthFactor == null) {
      return line;
    }
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: line,
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.height, this.radius = 16});

  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Bone(height: height, borderRadius: BorderRadius.circular(radius));
  }
}

class AsyncErrorPanel extends StatelessWidget {
  const AsyncErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppTheme.mutedInk,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить данные',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: GlassButton(
                onPressed: onRetry,
                label: 'Повторить',
                variant: GlassButtonVariant.tonal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
