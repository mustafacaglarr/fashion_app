import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/local_avatar_service.dart'; // eğer yerel avatarı temizlemek istiyorsan

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _deleteFlow() async {
    // Küçük onay: “SIL” yazmadan ilerleme
    if (_confirm.text.trim().toUpperCase() != "SIL") {
      setState(() => _error = "Devam etmek için kutuya SİL yazın.");
      return;
    }

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      setState(() => _error = "Oturum bulunamadı.");
      return;
    }

    setState(() { _busy = true; _error = null; });

    try {
      // 1) Son giriş süresi eskiyse yeniden yetkilendirme gerekecek olabilir
      try {
        // Eğer email/password sağlandıysa bununla re-auth dene
        if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
          await AuthService().reauthWithEmailPassword(_email.text.trim(), _password.text.trim());
        } else {
          // Email/şifre girilmediyse Google ile reauth opsiyonu deneyelim (başarısız olabilir)
          await AuthService().reauthWithGoogle();
        }
      } on FirebaseAuthException catch (e) {
        // requires-recent-login ⇒ kullanıcıya net mesaj ver
        if (e.code == 'requires-recent-login') {
          setState(() => _error = "Güvenlik için lütfen e-posta/şifre ile tekrar giriş bilgisi girin.");
          setState(() => _busy = false);
          return;
        } else {
          // başka bir auth hatası
          setState(() => _error = e.message ?? "Kimlik doğrulama başarısız.");
          setState(() => _busy = false);
          return;
        }
      }

      // 2) Kullanıcı verilerini temizle (Firestore + yerel avatar vs.)
      await AuthService().deleteUserData(); // Firestore users/{uid}, varsa diğer koleksiyonlar
      final uid = user.uid;
      await LocalAvatarService.clear(userId: uid); // yereldeki avatarı da silmek istersen

      // 3) Firebase Authentication hesabını sil
      await AuthService().deleteFirebaseUser();

      if (!mounted) return;
      // Başarılı: root’a dön (login kapısına)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hesabın ve verilerin silindi.")),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = "Silme işlemi başarısız: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Hesabı Sil")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Uyarı kartı
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
                    "Bu işlem kalıcıdır. Hesabın, geçmişin ve profil verilerin tamamen silinecek. "
                    "Üyeliğini dondurmak istersen destekten yardım alabilirsin.",
                    style: t.bodyMedium?.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text("Kimlik Doğrulama", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            "Güvenlik nedeniyle silmeden önce kimliğini doğrulaman gerekir. "
            "E-posta/şifre girerek veya Google ile yeniden doğrulayabilirsin.",
            style: t.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),

          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: "E-posta (opsiyonel)",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: "Şifre (opsiyonel)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () async {
                    // Sadece Google ile reauth denemek isteyenler için
                    setState(() => _error = null);
                    try {
                      setState(() => _busy = true);
                      await AuthService().reauthWithGoogle();
                      setState(() => _error = "Google ile doğrulama başarılı. Şimdi aşağıdan onayla.");
                    } catch (e) {
                      setState(() => _error = "Google doğrulaması başarısız: $e");
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text("Google ile Doğrula"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text("Onay", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            "Devam etmek için aşağıdaki kutuya büyük harflerle SİL yaz.",
            style: t.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirm,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: "SİL yaz",
              prefixIcon: Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                border: Border.all(color: Colors.red.withOpacity(.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _busy ? null : _deleteFlow,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Hesabı Kalıcı Olarak Sil"),
            ),
          ),
        ],
      ),
    );
  }
}
