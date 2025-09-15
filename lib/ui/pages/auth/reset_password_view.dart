// lib/ui/pages/auth/reset_password_view.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashion_app/services/password_reset_service.dart';

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

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });

    try {
      await PasswordResetService().sendResetEmail(_email.text);
      if (!mounted) return;
      // Basit başarı bildirimi (SnackBar yerine alt banner/overlay kullanıyorsan ona göre değiştir)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre sıfırlama bağlantısı gönderildi: ${_email.text.trim()}')),
      );
      Navigator.pop(context); // geri dön (örn. Profil/Güvenlik)
    } on FirebaseAuthException catch (e) {
      // En sık görülen hatalara nazik mesajlar
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'E-posta adresi geçersiz.';
          break;
        case 'user-not-found':
          msg = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'missing-email':
          msg = 'Lütfen e-posta girin.';
          break;
        default:
          msg = e.message ?? 'İşlem başarısız. Lütfen tekrar deneyin.';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Şifreyi Sıfırla')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('E-posta ile şifre sıfırla', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Kayıtlı e-posta adresini gir; sana şifre sıfırlama bağlantısı gönderelim.', style: t.bodyMedium),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(.2)),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 12),
          ],

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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                    if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Bağlantıyı Gönder'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Not: Gelen kutunu ve spam/junk klasörünü kontrol etmeyi unutma.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
