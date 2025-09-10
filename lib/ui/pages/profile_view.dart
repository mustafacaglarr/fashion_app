import 'package:fashion_app/ui/widgets/profile_header.dart';
import 'package:fashion_app/ui/widgets/section_title.dart';
import 'package:fashion_app/ui/widgets/setting_tile.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Üst başlık (avatar + ad + e-posta + plan rozeti)
          const ProfileHeader(
            name: "Mustafa Demir",
            email: "mustafa@example.com",
            planLabel: "Pro",
          ),
          const SizedBox(height: 16),

          const SectionTitle("Hesap"),
          SettingTile(
            leading: Icons.badge_rounded,
            title: "Profil Bilgileri",
            subtitle: "Ad, soyad, kullanıcı adı",
            onTap: () {/* profil düzenleme sayfasına git */},
          ),
          SettingTile(
            leading: Icons.lock_rounded,
            title: "Gizlilik",
            subtitle: "Veri işleme & izinler",
            onTap: () {/* gizlilik ayarları */},
          ),
          SettingTile.switcher(
            leading: Icons.verified_user_rounded,
            title: "Yüz verisini yerelde tut",
            subtitle: "Cihazda sakla, buluta gönderme",
            value: true,
            onChanged: (v) {/* toggle */},
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
            trailing: _Pill(text: "Pro • Aylık"),
            onTap: () {/* plan değiştirme */},
          ),
          SettingTile(
            leading: Icons.receipt_long_rounded,
            title: "Ödemeler",
            subtitle: "Faturalar ve geçmiş",
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
            onPressed: () {/* çıkış yap */},
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("Çıkış Yap"),
            ),
          ),
        ],
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
