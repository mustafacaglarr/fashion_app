import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fashion_app/ui/widgets/profile_header.dart';
import 'package:fashion_app/ui/widgets/section_title.dart';
import 'package:fashion_app/ui/widgets/setting_tile.dart';

// ⬇️ AuthGate'i import et (login/landing yöneten kapı)
import 'package:fashion_app/ui/pages/auth/auth_gate.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<Map<String, dynamic>?> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadUserData(),
        builder: (context, snapshot) {
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
              ),
              const SizedBox(height: 16),

              const SectionTitle("Hesap"),
              SettingTile(
                leading: Icons.badge_rounded,
                title: "Profil Bilgileri",
                subtitle: "Ad, soyad, kullanıcı adı",
                onTap: () {},
              ),
              SettingTile(
                leading: Icons.lock_rounded,
                title: "Gizlilik",
                subtitle: "Veri işleme & izinler",
                onTap: () {},
              ),
              SettingTile.switcher(
                leading: Icons.verified_user_rounded,
                title: "Yüz verisini yerelde tut",
                subtitle: "Cihazda sakla, buluta gönderme",
                value: true,
                onChanged: (v) {},
              ),

              const SizedBox(height: 12),
              const SectionTitle("Bildirimler"),
              SettingTile.switcher(
                leading: Icons.notifications_active_rounded,
                title: "Push Bildirimleri",
                subtitle: "Kampanya ve sonuç hatırlatmaları",
                value: true,
                onChanged: (v) {},
              ),
              SettingTile.switcher(
                leading: Icons.email_rounded,
                title: "E-posta Bülteni",
                subtitle: "Haftalık ipuçları ve yenilikler",
                value: false,
                onChanged: (v) {},
              ),

              const SizedBox(height: 12),
              const SectionTitle("Abonelik"),
              SettingTile(
                leading: Icons.workspace_premium_rounded,
                title: "Planım",
                trailing: _Pill(text: plan),
                onTap: () {},
              ),

              const SizedBox(height: 12),
              const SectionTitle("Diğer"),
              SettingTile(
                leading: Icons.help_center_rounded,
                title: "Yardım & Destek",
                subtitle: "SSS, iletişim",
                onTap: () {},
              ),
              SettingTile(
                leading: Icons.info_rounded,
                title: "Hakkında",
                subtitle: "Sürüm: 1.0.0",
                onTap: () {},
              ),

              const SizedBox(height: 20),
     FilledButton.tonal(
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: Colors.red, // 🔴 İkon kırmızı
                ),
                const SizedBox(height: 16),
                const Text(
                  "Çıkış yapmak istediğine emin misin?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Vazgeç"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red, // 🔴 Kırmızı buton
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Çıkış Yap",
                          style: TextStyle(color: Colors.white),
                        ),
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
)



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
