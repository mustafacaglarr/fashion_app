import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tekrar hoş geldin 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Hesabına giriş yap ya da Google ile devam et.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: vm.isBusy ? null : () async {
                        if (!_form.currentState!.validate()) return;
                        final ok = await vm.login(email: _email.text.trim(), password: _password.text.trim());
                        if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Hata')));
                        }
                      },
                      child: vm.isBusy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Giriş Yap'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: vm.isBusy ? null : () async {
                        if (_email.text.isNotEmpty) {
                          await vm.resetPassword(_email.text.trim());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi.')));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen e-posta girin.')));
                        }
                      },
                      child: const Text('Şifreni mi unuttun?'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: Divider()), SizedBox(width: 8), Text('veya'), SizedBox(width: 8), Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Image.asset('assets/google.png', height: 20), // küçük google ikon (opsiyonel)
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
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
