// lib/ui/pages/auth/register_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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

  String? _error; // hata mesajı

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
      appBar: AppBar(title: Text(tr('auth.register_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              tr('auth.join_us'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              tr('auth.register_subtitle'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),

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
                    decoration: InputDecoration(
                      labelText: tr('auth.full_name'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? tr('errors.name_required')
                        : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: tr('auth.email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? tr('errors.email_invalid') : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: tr('auth.password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? tr('errors.password_min') : null,
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
                                final code = vm.error ?? '';
                                final msg = code.contains('email-already-in-use')
                                    ? tr('errors.email_in_use')
                                    : tr('errors.register_generic');
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
                          : Text(tr('auth.submit_register')),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tr('auth.already_member')),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('auth.sign_in')),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: Image.asset('assets/google.png', height: 20),
                    label: Text(tr('auth.register_with_google')),
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
