import 'package:creative_gym_mobile/features/profile/data/mock_profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/profile_work_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ProfilePhotoViewerScreen extends StatefulWidget {
  const ProfilePhotoViewerScreen({
    super.key,
    required this.initialIndex,
    required this.winnersOnly,
    this.works,
  });

  final int initialIndex;
  final bool winnersOnly;
  final List<ProfileWork>? works;

  @override
  State<ProfilePhotoViewerScreen> createState() =>
      _ProfilePhotoViewerScreenState();
}

class _ProfilePhotoViewerScreenState extends State<ProfilePhotoViewerScreen> {
  late final List<ProfileWork> _works;
  late final PageController _controller;
  late int _currentPage;
  final Set<int> _zoomedPages = {};

  @override
  void initState() {
    super.initState();
    _works =
        widget.works ??
        (widget.winnersOnly
            ? mockProfileData.works
                  .where((work) => work.isWinner)
                  .toList(growable: false)
            : mockProfileData.works);
    final safeIndex = _works.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _works.length - 1);
    _currentPage = safeIndex;
    _controller = PageController(initialPage: safeIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const ValueKey('profile-photo-viewer'),
              controller: _controller,
              physics: _zoomedPages.contains(_currentPage)
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _works.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _ZoomableProfileWork(
                  work: _works[index],
                  onZoomChanged: (isZoomed) {
                    final changed = isZoomed
                        ? _zoomedPages.add(index)
                        : _zoomedPages.remove(index);
                    if (changed && mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            ),
            Positioned(
              left: 12,
              top: 0,
              child: SafeArea(
                child: Semantics(
                  button: true,
                  label: 'Назад',
                  child: IconButton.filled(
                    key: const ValueKey('close-photo-viewer'),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x66000000),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: context.pop,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableProfileWork extends StatefulWidget {
  const _ZoomableProfileWork({required this.work, required this.onZoomChanged});

  final ProfileWork work;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableProfileWork> createState() => _ZoomableProfileWorkState();
}

class _ZoomableProfileWorkState extends State<_ZoomableProfileWork> {
  late final TransformationController _transformationController;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _syncZoomState() {
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed == _isZoomed) {
      return;
    }

    setState(() => _isZoomed = isZoomed);
    widget.onZoomChanged(isZoomed);
  }

  void _finishInteraction() {
    if (_transformationController.value.getMaxScaleOnAxis() <= 1.01) {
      _transformationController.value = Matrix4.identity();
    }
    _syncZoomState();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      key: ValueKey('zoomable-profile-work-${widget.work.id}'),
      transformationController: _transformationController,
      minScale: 1,
      maxScale: 5,
      panEnabled: _isZoomed,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      onInteractionUpdate: (_) => _syncZoomState(),
      onInteractionEnd: (_) => _finishInteraction(),
      child: SizedBox.expand(
        child: ProfileWorkArtwork(work: widget.work, fit: BoxFit.contain),
      ),
    );
  }
}
