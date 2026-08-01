import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/auth/domain/auth_user.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  late Future<AuthUser> _userFuture;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _reload() {
    _userFuture = appDependencies.auth.getCurrentUser();
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _message('Введите почту полностью.');
      return;
    }
    await _run('email', () async {
      await appDependencies.auth.startEmailVerification(email);
      if (!mounted) return;
      setState(_reload);
      _message('Письмо отправлено. Приложением уже можно пользоваться.');
    });
  }

  Future<void> _connectYandex() async {
    await _run('yandex', () async {
      final value = await appDependencies.auth.startYandex();
      final opened = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Не удалось открыть Яндекс ID.');
    });
  }

  Future<void> _createPasskey() async {
    await _run('passkey', () async {
      await appDependencies.auth.createPasskey();
      if (!mounted) return;
      setState(_reload);
      _message('Ключ доступа создан.');
    });
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
    } catch (error) {
      if (mounted) _message(userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Аккаунт',
      showBackButton: true,
      body: FutureBuilder<AuthUser>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загружаем аккаунт…');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: () => setState(_reload),
            );
          }
          final user = snapshot.data!;
          if (_emailController.text.isEmpty && user.email.isNotEmpty) {
            _emailController.text = user.email;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              GlassPanel(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.primaryDark,
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.isGuest
                                  ? 'Гостевой аккаунт'
                                  : 'Аккаунт можно восстановить',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.mutedInk),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Почта',
                subtitle: user.emailVerified
                    ? 'Подтверждена — призовые очки начисляются.'
                    : 'Можно пользоваться сразу. Призовые очки появятся после подтверждения.',
                trailing: user.emailVerified
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryDark,
                      )
                    : null,
                child: user.emailVerified
                    ? Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'name@example.com',
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassButton(
                            label: _busy == 'email'
                                ? 'Отправляем…'
                                : 'Подтвердить почту',
                            onPressed: _sendEmail,
                            variant: GlassButtonVariant.tonal,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Яндекс ID',
                subtitle: user.hasYandex
                    ? 'Подключён.'
                    : 'Быстрый вход без пароля.',
                trailing: user.hasYandex
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryDark,
                      )
                    : null,
                child: user.hasYandex
                    ? const SizedBox.shrink()
                    : GlassButton(
                        label: _busy == 'yandex'
                            ? 'Открываем…'
                            : 'Подключить Яндекс ID',
                        onPressed: _connectYandex,
                        variant: GlassButtonVariant.tonal,
                      ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Ключ доступа',
                subtitle: user.hasPasskey
                    ? 'Создан — можно входить отпечатком или кодом телефона.'
                    : user.isGuest
                    ? 'Сначала подтвердите почту или подключите Яндекс ID.'
                    : 'Вход отпечатком, Face ID или кодом устройства.',
                trailing: user.hasPasskey
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryDark,
                      )
                    : null,
                child: user.hasPasskey || user.isGuest
                    ? const SizedBox.shrink()
                    : GlassButton(
                        label: _busy == 'passkey'
                            ? 'Создаём…'
                            : 'Создать ключ доступа',
                        onPressed: _createPasskey,
                        variant: GlassButtonVariant.tonal,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
