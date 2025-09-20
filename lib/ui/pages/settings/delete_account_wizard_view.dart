import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../services/auth_service.dart';
import '../../../services/local_avatar_service.dart';
import '../auth/auth_gate.dart';

enum _DelStep { intro, reauth, confirm }

class DeleteAccountWizardView extends StatefulWidget {
  const DeleteAccountWizardView({super.key});

  @override
  State<DeleteAccountWizardView> createState() => _DeleteAccountWizardViewState();
}

class _DeleteAccountWizardViewState extends State<DeleteAccountWizardView> {
  _DelStep _step = _DelStep.intro;

  // Reauth (email/şifre) alanları
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPass = false;
  bool _reauthenticated = false;

  // Son onay
  final _confirm = TextEditingController();

  // Durum
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _goNext() {
    setState(() {
      if (_step == _DelStep.intro) _step = _DelStep.reauth;
      else if (_step == _DelStep.reauth) _step = _DelStep.confirm;
    });
  }

  void _goBack() {
    setState(() {
      if (_step == _DelStep.confirm) _step = _DelStep.reauth;
      else if (_step == _DelStep.reauth) _step = _DelStep.intro;
    });
  }

  // Firebase hata kodlarını çeviri anahtarlarına map’le
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return tr('delete.errors.codes.user_not_found');
      case 'wrong-password':
        return tr('delete.errors.codes.wrong_password');
      case 'invalid-email':
        return tr('delete.errors.codes.invalid_email');
      case 'missing-credentials':
        return tr('delete.errors.codes.missing_credentials');
      case 'user-disabled':
        return tr('delete.errors.codes.user_disabled');
      case 'too-many-requests':
        return tr('delete.errors.codes.too_many_requests');
      default:
        return tr('delete.errors.codes.auth_failed', namedArgs: {'code': code});
    }
  }

  Future<void> _tryReauthEmail() async {
    setState(() { _busy = true; _error = null; });
    try {
      if (_email.text.trim().isEmpty || _password.text.isEmpty) {
        throw FirebaseAuthException(code: 'missing-credentials', message: tr('delete.errors.missing_credentials'));
      }
      await AuthService().reauthWithEmailPassword(_email.text.trim(), _password.text);
      setState(() => _reauthenticated = true);
      _goNext();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapFirebaseError(e.code));
    } catch (e) {
      setState(() => _error = tr('errors.unexpected_with_detail', namedArgs: {'error': e.toString()}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tryReauthGoogle() async {
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService().reauthWithGoogle();
      setState(() => _reauthenticated = true);
      _goNext();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? tr('delete.errors.google_failed'));
    } catch (e) {
      setState(() => _error = tr('errors.unexpected_with_detail', namedArgs: {'error': e.toString()}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _performDelete() async {
    final requiredWord = tr('delete.wizard.confirm_word').toUpperCase();
    if (_confirm.text.trim().toUpperCase() != requiredWord) {
      setState(() => _error = tr('delete.wizard.confirm_mismatch', namedArgs: {'word': requiredWord}));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = tr('delete.errors.session_missing'));
      return;
    }

    setState(() { _busy = true; _error = null; });
    try {
      // Verileri temizle
      await AuthService().deleteUserData();
      await LocalAvatarService.clear(userId: user.uid);

      // Hesabı sil
      await AuthService().deleteFirebaseUser();

      if (!mounted) return;
      // Başarılı → login kapısına dön
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(tr('delete.dialog.title')),
          content: Text(tr('delete.dialog.content')),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (_) => false,
                );
              },
              child: Text(tr('common.ok')),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? tr('delete.errors.needs_recent_login'));
    } catch (e) {
      setState(() => _error = tr('delete.errors.delete_failed', namedArgs: {'error': e.toString()}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('delete.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _WizardHeader(step: _step),

            const SizedBox(height: 16),
            if (_error != null) _ErrorBanner(message: _error!),

            // STEP BODIES
            switch (_step) {
              _DelStep.intro => _IntroStep(onNext: _goNext),
              _DelStep.reauth => _ReauthStep(
                email: _email,
                password: _password,
                showPass: _showPass,
                onTogglePass: () => setState(() => _showPass = !_showPass),
                busy: _busy,
                onBack: _goBack,
                onEmailReauth: _tryReauthEmail,
                onGoogleReauth: _tryReauthGoogle,
              ),
              _DelStep.confirm => _ConfirmStep(
                confirmCtrl: _confirm,
                busy: _busy,
                onBack: _goBack,
                onDelete: _performDelete,
              ),
            },

            if (_step == _DelStep.reauth && _reauthenticated) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(tr('delete.wizard.verified'), style: t.bodyMedium?.copyWith(color: Colors.green)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Üstte basit bir başlık + ilerleme çubuğu
class _WizardHeader extends StatelessWidget {
  final _DelStep step;
  const _WizardHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final titles = [
      tr('delete.steps.warning'),
      tr('delete.steps.reauth'),
      tr('delete.steps.confirm'),
    ];
    final idx = step == _DelStep.intro ? 0 : step == _DelStep.reauth ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i <= idx;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? Colors.redAccent : const Color(0xFFE1E3EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final isCurrent = i == idx;
            return Text(
              titles[i],
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent ? Colors.redAccent : Colors.black54,
                  ),
            );
          }),
        ),
      ],
    );
  }
}

/// Adım 1: Bilgilendirme
class _IntroStep extends StatelessWidget {
  final VoidCallback onNext;
  const _IntroStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.06),
            border: Border.all(color: Colors.red.withOpacity(.2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('delete.wizard.warning_text'),
                  style: t.bodyMedium?.copyWith(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(.79),
            foregroundColor: Colors.white,
          ),
          onPressed: onNext,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(tr('common.continue')),
          ),
        ),
      ],
    );
  }
}

/// Adım 2: Re-auth seçenekleri
class _ReauthStep extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool showPass;
  final VoidCallback onTogglePass;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onEmailReauth;
  final VoidCallback onGoogleReauth;

  const _ReauthStep({
    required this.email,
    required this.password,
    required this.showPass,
    required this.onTogglePass,
    required this.busy,
    required this.onBack,
    required this.onEmailReauth,
    required this.onGoogleReauth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Başlık ---
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              tr('delete.steps.reauth_title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // --- Kart ---
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Email
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  labelText: tr('auth.email'),
                  hintText: tr('delete.inputs.email_hint'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Şifre
              TextField(
                controller: password,
                obscureText: !showPass,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  labelText: tr('auth.password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: onTogglePass,
                    icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
                    tooltip: showPass ? tr('delete.inputs.hide_password') : tr('delete.inputs.show_password'),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 12),

              // E-posta ile doğrula
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: busy ? null : onEmailReauth,
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.blue),
                  label: Text(tr('delete.actions.reauth_email')),
                ),
              ),

              const SizedBox(height: 10),

              // "veya" ayırıcı
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      tr('auth.or'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 10),

              // Google ile doğrula
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: busy ? null : onGoogleReauth,
                  icon: Image.asset('assets/google.png', height: 20, width: 20),
                  label: Text(tr('delete.actions.reauth_google')),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Alt aksiyonlar
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: busy ? null : onBack,
                child: Text(tr('common.back')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Adım 3: Son onay ve silme
class _ConfirmStep extends StatelessWidget {
  final TextEditingController confirmCtrl;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _ConfirmStep({
    required this.confirmCtrl,
    required this.busy,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final requiredWord = tr('delete.wizard.confirm_word');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('delete.wizard.confirm_instruction', namedArgs: {'word': requiredWord}), style: t.bodyMedium),
        const SizedBox(height: 10),
        TextField(
          controller: confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: tr('delete.wizard.confirm_label', namedArgs: {'word': requiredWord}),
            prefixIcon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Back
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: busy ? null : onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                label: Text(tr('common.back'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),

            // Delete (destructive)
           // Delete (destructive)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_forever_rounded),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: busy
                      ? const SizedBox(
                          key: ValueKey('prog'),
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          tr('delete.actions.delete_permanently'),
                          key: const ValueKey('text'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            )
              ],
            )

      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.06),
        border: Border.all(color: Colors.red.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
