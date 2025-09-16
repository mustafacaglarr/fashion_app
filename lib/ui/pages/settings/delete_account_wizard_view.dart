import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

String _mapFirebaseErrorToTr(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Böyle bir kullanıcı bulunamadı.';
    case 'wrong-password':
      return 'Şifre hatalı. Lütfen tekrar deneyin.';
    case 'invalid-email':
      return 'Geçersiz e-posta adresi.';
    case 'missing-credentials':
      return 'E-posta ve şifre gerekli.';
    case 'user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'too-many-requests':
      return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    default:
      return 'Kimlik doğrulama başarısız. (${code})';
  }
}


 Future<void> _tryReauthEmail() async {
  setState(() { _busy = true; _error = null; });
  try {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      throw FirebaseAuthException(code: 'missing-credentials', message: 'E-posta ve şifre gerekli');
    }
    await AuthService().reauthWithEmailPassword(_email.text.trim(), _password.text);
    setState(() => _reauthenticated = true);
    _goNext();
  } on FirebaseAuthException catch (e) {
    setState(() => _error = _mapFirebaseErrorToTr(e.code));
  } catch (e) {
    setState(() => _error = 'Bir hata oluştu: $e');
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
      setState(() => _error = e.message ?? 'Google doğrulaması başarısız.');
    } catch (e) {
      setState(() => _error = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _performDelete() async {
    if (_confirm.text.trim().toUpperCase() != 'SİL') {
      setState(() => _error = 'Devam etmek için kutuya SİL yazın.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Oturum bulunamadı.');
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
          title: const Text('Hesap Silindi'),
          content: const Text('Hesabın ve verilerin kalıcı olarak kaldırıldı.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (_) => false,
                );
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      // requires-recent-login tipik hata: kullanıcı step 2’yi atlamış olabilir
      setState(() => _error = e.message ?? 'Silme işlemi başarısız (yeniden giriş gerekli olabilir).');
    } catch (e) {
      setState(() => _error = 'Silme işlemi başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabı Sil')),
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
                  Text('Kimlik doğrulandı', style: t.bodyMedium?.copyWith(color: Colors.green)),
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
    final titles = const ['Uyarı', 'Kimlik Doğrulama', 'Son Onay'];
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
                  "Bu işlem kalıcıdır. Hesap bilgilerin, geçmiş görsellerin ve yerel profil avatarın silinecek.",
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
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Devam Et'),
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
      Icon(Icons.verified_user_rounded, color: Colors.blue,),
      const SizedBox(width: 8),
      Text(
        'Kimlik Doğrulama',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
            labelText: 'E-posta',
            hintText: 'ornek@mail.com',
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
            labelText: 'Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onTogglePass,
              icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
              tooltip: showPass ? 'Şifreyi gizle' : 'Şifreyi göster',
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
        // İnce ayraç
        Divider(color: Colors.grey.shade300, height: 1),

        const SizedBox(height: 12),

        // E-posta ile doğrula
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade800, // label rengi
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: busy ? null : onEmailReauth,
            icon: const Icon(
              Icons.verified_user_rounded,
              color: Colors.blue, // sadece ikon mavi
            ),
            label: const Text('E-posta ile Doğrula'),
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
                'veya',
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
            icon: Image.asset(
              'assets/google.png',
              height: 20,
              width: 20,
            ),
            label: const Text('Google ile Doğrula'),
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
          child: const Text('Geri'),
        ),
      ),
    ],
  ),
]

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Devam etmek için aşağıdaki kutuya büyük harflerle SİL yaz.", style: t.bodyMedium),
        const SizedBox(height: 10),
        TextField(
          controller: confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: "SİL yaz",
            prefixIcon: Icon(Icons.delete_forever_rounded, color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
       Row(
  children: [
    // Geri (nötr)
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
        label: const Text(
          'Geri',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    const SizedBox(width: 12),

    // Sil (destructive)
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
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: busy
              ? const SizedBox(
                  key: ValueKey('prog'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Kalıcı Olarak Sil',
                  key: ValueKey('text'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    ),
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
