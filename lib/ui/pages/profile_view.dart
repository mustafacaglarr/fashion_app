import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/services/auth_service.dart';
import 'package:fashion_app/services/local_avatar_service.dart';
import 'package:fashion_app/ui/pages/auth/reset_password_view.dart';
import 'package:fashion_app/ui/pages/settings/delete_account_view.dart';
import 'package:fashion_app/ui/pages/settings/delete_account_wizard_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// UI widgets
import 'package:fashion_app/ui/widgets/profile_header.dart';
import 'package:fashion_app/ui/widgets/section_title.dart';
import 'package:fashion_app/ui/widgets/setting_tile.dart';

// AuthGate
import 'package:fashion_app/ui/pages/auth/auth_gate.dart';

// Ayar VM
import 'package:fashion_app/ui/viewmodels/settings_viewmodel.dart';

// Sayfalar
import 'settings/profile_edit_view.dart';
import 'settings/privacy_settings_view.dart';
import 'settings/notifications_view.dart';
import 'settings/plan_view.dart';
import 'settings/help_support_view.dart';
import 'settings/about_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<Map<String, dynamic>?> _userFuture; // 🔒 Cache’lenmiş future
  String? _localAvatarPath;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> _loadLocalAvatar() async {
    _localAvatarPath = await LocalAvatarService.getSavedPath(userId: _userId);
  }

  Future<Map<String, dynamic>?> _loadUserData() async {
    // Firebase firestore’dan isim/email çekiyorsun; istersen orayı da kaldırabilirsin.
    // Sadece yerel avatar için _loadLocalAvatar çağrısı yeterli.
    await _loadLocalAvatar();
    // mevcut Firestore kodun:
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return snap.data();
  }

  @override
  void initState() {
    super.initState();
    // Firestore çağrısını bir kez al ve sakla; rebuild’lerde tekrar çağrılmasın
    _userFuture = _loadUserData();

    // Settings VM’yi yükle (listen: false → rebuild tetiklemez)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture, // ✅ cache’lenmiş future
        builder: (context, snapshot) {
          // Yumuşak geçiş için AnimatedSwitcher (opsiyonel ama güzel)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Kullanıcı bilgileri bulunamadı"));
          }

          final data = snapshot.data!;
          final name = data['name'] ?? 'Bilinmiyor';
          final email = data['email'] ?? '—';
          final plan = (data['plan'] ?? 'free').toString().toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              ProfileHeader(
                name: name,
                email: email,
                planLabel: plan,
                localAvatarPath: _localAvatarPath, // ⬅️ yerel yolu ver
                userId: _userId,                    // ⬅️ kaydetme anahtarı
                onAvatarChanged: (newPath) {
                  // anında state’i güncelle (Firestore yok)
                  setState(() => _localAvatarPath = newPath);
                },
              ),
              const SizedBox(height: 16),

              const SectionTitle("Hesap & Güvenlik"),
              SettingTile(
                leading: Icons.badge_rounded,
                title: "Profil Bilgileri",
                subtitle: "Ad, soyad, E-posta",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileEditView(currentName: name, currentEmail: email),
                  ),
                ),
              ),
              SettingTile(
                leading: Icons.security_outlined,
                title: "Gizlilik",
                subtitle: "Veri işleme & izinler",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsView())),
              ),
              // Örnek: ProfileView içinde bir SettingTile
              SettingTile(
                leading: Icons.lock_rounded,
                title: "Şifreyi Sıfırla",
                subtitle: "E-posta ile sıfırlama bağlantısı gönder",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResetPasswordView()),
                ),
              ),

              SettingTile(
                leading: Icons.delete_forever_rounded,
                title: "Hesabı Sil",
                subtitle: "Tüm verileri kalıcı olarak kaldır",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeleteAccountWizardView()),
                ),
              ),
              // 🔽 Sadece bu satır rebuild olsun (switch değişince tüm sayfa değil)
              Consumer<SettingsViewModel>(
                builder: (_, settings, __) => SettingTile.switcher(
                  leading: Icons.verified_user_rounded,
                  title: "Yüz verisini yerelde tut",
                  subtitle: "Cihazda sakla, buluta gönderme",
                  value: settings.faceLocalStore,
                  onChanged: (v) => settings.setFaceLocalStore(v),
                ),
              ),

              const SizedBox(height: 12),
              const SectionTitle("Bildirimler"),

              // Bu da sadece kendi sayfasına götürüyor (rebuild yok)
              SettingTile(
                leading: Icons.notifications_active_rounded,
                title: "Push Bildirimleri",
                subtitle: "Kampanya ve sonuç hatırlatmaları",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView())),
              ),
              const SizedBox(height: 12),
              const SectionTitle("Abonelik"),
              SettingTile(
                leading: Icons.workspace_premium_rounded,
                title: "Planım",
                trailing: _Pill(text: plan),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanView())),
              ),

              const SizedBox(height: 12),
              const SectionTitle("Diğer"),
              SettingTile(
                leading: Icons.help_center_rounded,
                title: "Yardım & Destek",
                subtitle: "SSS, iletişim",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportView())),
              ),
              SettingTile(
                leading: Icons.info_rounded,
                title: "Hakkında",
                subtitle: "Sürüm: 1.0.0",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutView())),
              ),

              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout_rounded, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(
                                "Çıkış yapmak istediğine emin misin?",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Vazgeç"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (confirm == true) {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (_) => false,
                      );
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Çıkış Yap"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
