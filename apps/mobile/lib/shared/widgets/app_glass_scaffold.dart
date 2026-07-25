import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;

class AppGlassScaffold extends StatelessWidget {
  const AppGlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.actions = const [],
  });

  final String? title;
  final Widget body;
  final bool showBackButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return liquid.GlassScaffold(
      statusBarStyle: liquid.GlassStatusBarStyle.dark,
      background: const AppBackground(child: SizedBox.expand()),
      extendBody: false,
      edgeFade: false,
      appBarHeight: 56,
      appBar: liquid.GlassAppBar(
        preferredSize: const Size.fromHeight(56),
        centerTitle: false,
        leading: showBackButton
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Semantics(
                  button: true,
                  label: 'Назад',
                  child: liquid.GlassIconButton(
                    size: 42,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.ink,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              )
            : null,
        title: title == null
            ? null
            : Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: actions,
      ),
      body: body,
    );
  }
}

class AppGlassHeaderAction extends StatelessWidget {
  const AppGlassHeaderAction({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: liquid.GlassIconButton(
        size: 42,
        icon: Icon(icon, color: AppTheme.ink),
        onPressed: onPressed,
      ),
    );
  }
}
