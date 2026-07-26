import 'dart:typed_data';

import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:flutter/material.dart';

class AuthenticatedMedia extends StatefulWidget {
  const AuthenticatedMedia({
    super.key,
    required this.mediaUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String mediaUrl;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<AuthenticatedMedia> createState() => _AuthenticatedMediaState();
}

class _AuthenticatedMediaState extends State<AuthenticatedMedia> {
  Future<Uint8List>? _future;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _prepare();
    }
  }

  void _prepare() {
    _future = widget.mediaUrl.isEmpty
        ? null
        : appDependencies.media.load(widget.mediaUrl);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return widget.fallback;
    }
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final loaded = bytes != null && bytes.isNotEmpty;
        return AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: loaded
              ? Image.memory(
                  bytes,
                  key: ValueKey('media-${widget.mediaUrl}'),
                  fit: widget.fit,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => widget.fallback,
                )
              : KeyedSubtree(
                  key: ValueKey('media-placeholder-${widget.mediaUrl}'),
                  child: widget.fallback,
                ),
        );
      },
    );
  }
}
