// lib/ui/pages/auth/register_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';     // Plan.basic için
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

                  // ⬇️ PLAN SEÇİMİ KALDIRILDI — herkes BASIC/FREE olacak

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
                                plan: Plan.basic, // ⬅️ her zaman FREE/BASIC
                              );
                              if (!ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(vm.error ?? 'Hata')),
                                );
                              } else {
                                if (mounted) Navigator.pop(context); // AuthGate otomatik yönlendirir
                              }
                            },
                      child: vm.isBusy
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                  // Google ile kayıt → ilk girişte de Plan.basic yazılacak (AuthService.loginWithGoogle planHint null ise basic)
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
