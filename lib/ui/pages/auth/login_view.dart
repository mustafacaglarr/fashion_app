// lib/ui/pages/auth/login_view.dart
import 'package:fashion_app/ui/pages/auth/reset_password_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showError = false; // 🔴 sadece sabit mesajı kontrol için

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tekrar hoş geldin 👋',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Hesabına giriş yap ya da Google ile devam et.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 18),

            // 🔴 Sabit hata mesajı (yanlış girişlerde gösterilecek)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: !_showError
                  ? const SizedBox.shrink()
                  : const _ErrorBanner(
                      key: ValueKey('login-error'),
                      message: 'Lütfen girdiğiniz bilgileri kontrol ediniz.',
                    ),
            ),

            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: vm.isBusy
                          ? null
                          : () async {
                              if (!_form.currentState!.validate()) return;
                              final ok = await vm.login(
                                email: _email.text.trim(),
                                password: _password.text.trim(),
                              );

                              // 🔴 Başarısız olursa sabit hata mesajını aç
                              if (!ok && mounted) {
                                setState(() => _showError = true);
                              } else {
                                setState(() => _showError = false);
                              }
                            },
                      child: vm.isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Giriş Yap'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResetPasswordView()),
                        );
                      },
                      child: const Text('Şifreni mi unuttun?'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(child: Divider()),
                SizedBox(width: 8),
                Text('veya'),
                SizedBox(width: 8),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Image.asset('assets/google.png', height: 20),
                label: const Text('Google ile devam et'),
                onPressed: vm.isBusy ? null : () => vm.loginWithGoogle(),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Hesabın yok mu?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterView()),
                    );
                  },
                  child: const Text('Kayıt ol'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔴 Sabit hata banner'ı
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.08),
        border: Border.all(color: Colors.red.withOpacity(.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
