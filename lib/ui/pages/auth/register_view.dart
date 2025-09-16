// lib/ui/pages/auth/register_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart'; // Plan.basic için
import '../../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  String? _error; // 🔴 hata mesajı burada tutulacak

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Aramıza katıl! 🚀',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'E-posta ve şifre ile ücretsiz hesabını oluştur. '
              'İstersen daha sonra Pro/Expert plana yükseltebilirsin.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),

            // 🔴 Hata mesajı kutusu
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Adınızı girin' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: vm.isBusy
                          ? null
                          : () async {
                              if (!_form.currentState!.validate()) return;
                              final ok = await vm.register(
                                name: _name.text.trim(),
                                email: _email.text.trim(),
                                password: _password.text.trim(),
                                plan: Plan.free,
                              );

                              if (!ok && mounted) {
                                // Firebase’den gelen hataya göre mesaj ayarla
                                final code = vm.error ?? '';
                                String msg;
                                if (code.contains('email-already-in-use')) {
                                  msg =
                                      "Bu e-posta adresiyle zaten bir hesap oluşturulmuş. Lütfen giriş yapmayı deneyin.";
                                } else {
                                  msg = "Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.";
                                }
                                setState(() => _error = msg);
                              } else {
                                if (mounted) Navigator.pop(context);
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
                          : const Text('Kayıt Ol'),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaten üye misin?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Giriş yap'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: Image.asset('assets/google.png', height: 20),
                    label: const Text('Google ile kayıt ol'),
                    onPressed: vm.isBusy ? null : () => vm.loginWithGoogle(planHint: Plan.basic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
