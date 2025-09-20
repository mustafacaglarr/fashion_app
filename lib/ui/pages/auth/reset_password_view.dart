// lib/ui/pages/auth/reset_password_view.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashion_app/services/password_reset_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  bool _sent = false; // başarı ekranı için
  String _sentTo = "";

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final mail = _email.text.trim();
      await PasswordResetService().sendResetEmail(mail);

      if (!mounted) return;
      setState(() {
        _sent = true;
        _sentTo = mail;
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = tr('errors.email_invalid');
          break;
        case 'user-not-found':
          msg = tr('errors.reset_user_not_found');
          break;
        case 'missing-email':
          msg = tr('errors.email_required');
          break;
        default:
          msg = tr('errors.reset_generic');
      }
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      if (mounted) {
        setState(() => _error = tr('errors.unexpected_with_detail', namedArgs: {'error': '$e'}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('auth.reset.title'))),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _sent
            // ✅ BAŞARI EKRANI
            ? ListView(
                key: const ValueKey('success'),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFE3D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('auth.reset.success_title'),
                                style: t.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr('auth.reset.success_desc',
                                    namedArgs: {'email': _sentTo}),
                                style: t.bodyMedium?.copyWith(
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Text(tr('auth.reset.back')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('auth.reset.success_tip'),
                    style: t.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              )
            // 📝 FORM EKRANI
            : ListView(
                key: const ValueKey('form'),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    tr('auth.reset.form_title'),
                    style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('auth.reset.form_subtitle'),
                    style: t.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                            labelText: tr('auth.email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return tr('errors.email_required');
                            }
                            if (!v.contains('@')) {
                              return tr('errors.email_invalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(tr('auth.reset.send_link')),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    tr('auth.reset.note'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
      ),
    );
  }
}
