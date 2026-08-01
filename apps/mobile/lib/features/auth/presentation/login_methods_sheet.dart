import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum LoginMethodResult { emailSent, signedIn }

Future<LoginMethodResult?> showLoginMethods(BuildContext context) {
  return showModalBottomSheet<LoginMethodResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LoginMethodsSheet(),
  );
}

class _LoginMethodsSheet extends StatefulWidget {
  const _LoginMethodsSheet();

  @override
  State<_LoginMethodsSheet> createState() => _LoginMethodsSheetState();
}

class _LoginMethodsSheetState extends State<_LoginMethodsSheet> {
  final _emailController = TextEditingController();
  String? _busyMethod;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _email() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Введите почту полностью.');
      return;
    }
    await _run('email', () async {
      await appDependencies.auth.startEmailVerification(email);
      if (mounted) Navigator.pop(context, LoginMethodResult.emailSent);
    });
  }

  Future<void> _yandex() async {
    await _run('yandex', () async {
      final value = await appDependencies.auth.startYandex();
      final opened = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Не удалось открыть Яндекс ID.');
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _passkey() async {
    await _run('passkey', () async {
      await appDependencies.auth.signInWithPasskey();
      if (mounted) Navigator.pop(context, LoginMethodResult.signedIn);
    });
  }

  Future<void> _run(String method, Future<void> Function() action) async {
    if (_busyMethod != null) return;
    setState(() {
      _busyMethod = method;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busyMethod = null;
          _error = userErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Войти',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Вернитесь к своим работам и очкам.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autocorrect: false,
              onSubmitted: (_) => _email(),
              decoration: InputDecoration(
                hintText: 'Почта',
                suffixIcon: IconButton(
                  tooltip: 'Отправить ссылку',
                  onPressed: _busyMethod == null ? _email : null,
                  icon: _busyMethod == 'email'
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busyMethod == null ? _yandex : null,
              icon: const Text(
                'Я',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              label: Text(
                _busyMethod == 'yandex'
                    ? 'Открываем…'
                    : 'Продолжить с Яндекс ID',
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busyMethod == null ? _passkey : null,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(
                _busyMethod == 'passkey'
                    ? 'Проверяем…'
                    : 'Войти по ключу доступа',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
