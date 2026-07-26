import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';

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

class AsyncLoadingPanel extends StatefulWidget {
  const AsyncLoadingPanel({
    super.key,
    this.message = 'Загрузка...',
    this.layout = AsyncLoadingLayout.detail,
  });

  final String message;
  final AsyncLoadingLayout layout;

  @override
  State<AsyncLoadingPanel> createState() => _AsyncLoadingPanelState();
}

class _AsyncLoadingPanelState extends State<AsyncLoadingPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.message,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = reduceMotion ? 0.5 : _controller.value;
            final color = Color.lerp(
              const Color(0xFFE2E7E2),
              const Color(0xFFF0F2ED),
              Curves.easeInOut.transform(progress),
            )!;
            return _SkeletonLayout(layout: widget.layout, color: color);
          },
        ),
      ),
    );
  }
}

class _SkeletonLayout extends StatelessWidget {
  const _SkeletonLayout({required this.layout, required this.color});

  final AsyncLoadingLayout layout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      AsyncLoadingLayout.list => _SkeletonList(color: color),
      AsyncLoadingLayout.photo => _SkeletonPhoto(color: color),
      AsyncLoadingLayout.voting => _SkeletonVoting(color: color),
      AsyncLoadingLayout.profile => _SkeletonProfile(color: color),
      AsyncLoadingLayout.detail => _SkeletonDetail(color: color),
    };
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-list'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonLine(color: color, widthFactor: 0.28, height: 18),
        const SizedBox(height: 14),
        for (var index = 0; index < 3; index++) ...[
          AspectRatio(
            aspectRatio: 16 / 8.4,
            child: _SkeletonBlock(color: color, radius: 24),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _SkeletonDetail extends StatelessWidget {
  const _SkeletonDetail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-detail'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonLine(color: color, widthFactor: 0.62, height: 30),
        const SizedBox(height: 12),
        _SkeletonLine(color: color, widthFactor: 0.38),
        const SizedBox(height: 28),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: _SkeletonBlock(color: color, radius: 24),
        ),
        const SizedBox(height: 24),
        _SkeletonLine(color: color, widthFactor: 0.88),
        const SizedBox(height: 10),
        _SkeletonLine(color: color, widthFactor: 0.72),
        const SizedBox(height: 28),
        _SkeletonBlock(color: color, height: 54, radius: 18),
      ],
    );
  }
}

class _SkeletonPhoto extends StatelessWidget {
  const _SkeletonPhoto({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-photo'),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonLine(color: color, widthFactor: 0.58, height: 26),
        const SizedBox(height: 10),
        _SkeletonLine(color: color, widthFactor: 0.34),
        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 430),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: _SkeletonBlock(color: color, radius: 22),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _SkeletonLine(color: color, widthFactor: 0.46, height: 20),
        const SizedBox(height: 18),
        _SkeletonBlock(color: color, height: 54, radius: 18),
      ],
    );
  }
}

class _SkeletonVoting extends StatelessWidget {
  const _SkeletonVoting({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('loading-skeleton-voting'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          _SkeletonLine(color: color, widthFactor: 0.62, height: 26),
          const SizedBox(height: 10),
          _SkeletonLine(color: color, widthFactor: 0.18),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _SkeletonBlock(color: color, radius: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _SkeletonBlock(color: color, radius: 20),
                ),
              ),
            ],
          ),
          const Spacer(),
          _SkeletonLine(color: color, widthFactor: 0.42),
          const SizedBox(height: 18),
          _SkeletonBlock(color: color, height: 54, radius: 18),
        ],
      ),
    );
  }
}

class _SkeletonProfile extends StatelessWidget {
  const _SkeletonProfile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('loading-skeleton-profile'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Center(
          child: _SkeletonBlock(
            color: color,
            width: 104,
            height: 104,
            radius: 52,
          ),
        ),
        const SizedBox(height: 18),
        Center(child: _SkeletonLine(color: color, width: 150, height: 24)),
        const SizedBox(height: 26),
        _SkeletonBlock(color: color, height: 132, radius: 24),
        const SizedBox(height: 26),
        _SkeletonLine(color: color, widthFactor: 0.28, height: 22),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var index = 0; index < 6; index++)
              _SkeletonBlock(color: color, radius: 3),
          ],
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.color,
    this.width,
    this.widthFactor,
    this.height = 14,
  });

  final Color color;
  final double? width;
  final double? widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final line = _SkeletonBlock(
      color: color,
      width: width,
      height: height,
      radius: height / 2,
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
  const _SkeletonBlock({
    required this.color,
    this.width,
    this.height,
    this.radius = 16,
  });

  final Color color;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppTheme.surfaceStroke.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
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
