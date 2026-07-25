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
              itemCount: _works.length,
              itemBuilder: (context, index) {
                return ProfileWorkArtwork(work: _works[index]);
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
